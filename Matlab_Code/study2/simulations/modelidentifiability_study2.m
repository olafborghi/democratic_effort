%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MODEL IDENTIFIABILITY, STUDY 2
%
% Aim:
% Simulate data from each of the six Study 2 models, fit all six candidate
% models back to each simulated dataset, and check whether model comparison
% recovers the true generating model.
%
% Study 2 model space:
% 1. ms_two_k_one_beta
% 2. ms_two_k_one_beta_linear
% 3. ms_two_k_one_beta_hyperbolic
% 4. ms_two_k_two_beta
% 5. ms_two_k_two_beta_linear
% 6. ms_two_k_two_beta_hyperbolic
%
% Outputs saved to:
% /Users/marianavonmohr/Desktop/Effort_computationalmodels/study2/simulations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc
clearvars

%% Paths

addpath('/Users/marianavonmohr/Desktop/Effort_computationalmodels/study2/Model_real_data/models');
addpath('/Users/marianavonmohr/Desktop/Effort_computationalmodels/study2/Model_real_data/tools');

spm_dir = '/Users/marianavonmohr/Desktop/spm12';
addpath(spm_dir);
addpath(fullfile(spm_dir,'src'));

workspace_dir = '/Users/marianavonmohr/Desktop/Effort_computationalmodels/study2/Model_real_data/workspaces';
sim_output_dir = '/Users/marianavonmohr/Desktop/Effort_computationalmodels/study2/simulations';

if ~isfolder(sim_output_dir)
    mkdir(sim_output_dir);
end

%% Settings

rng(123)

e = 'PM';

models = { ...
    'ms_two_k_one_beta', ...
    'ms_two_k_one_beta_linear', ...
    'ms_two_k_one_beta_hyperbolic', ...
    'ms_two_k_two_beta', ...
    'ms_two_k_two_beta_linear', ...
    'ms_two_k_two_beta_hyperbolic'};

nModels = numel(models);

% Cutler-style setting.
% For a quick test, set nRounds = 1 and nSubj = 50.
% For final analysis, use nRounds = 10 and nSubj = 100.
nRounds = 10;
nSubj   = 100;

% Parameter ranges
bounds.beta = [0, 10];

% From empirical Study 2 fits, k bounds are [0, 2]
k_range    = [0, 2];
beta_range = [0, 10];

%% Load empirical Study 2 workspace to get schedule

files = dir(fullfile(workspace_dir, 'EM_fit_results_full_democraticeffortdata*.mat'));

if isempty(files)
    error('No Study 2 EM workspace found in %s', workspace_dir);
end

[~, idx] = max([files.datenum]);
wsfile = fullfile(workspace_dir, files(idx).name);

load(wsfile, 's');

fprintf('Loaded empirical workspace: %s\n', files(idx).name);

%% Find valid Study 2 schedule

schedule = [];

for isub = 1:numel(s.(e).beh)

    Ttmp = struct2table(s.(e).beh{isub});

    if all(ismember({'agent','effort','reward','choice'}, Ttmp.Properties.VariableNames))

        n_trials = height(Ttmp);
        agents_present = sort(unique(Ttmp.agent));

        if n_trials == 18 && isequal(agents_present(:), [1;2])
            schedule = Ttmp;

            fprintf('Using schedule from subject %s with %d trials and agents [%s].\n', ...
                s.(e).ID{isub}, n_trials, num2str(agents_present(:)'));

            break
        end
    end
end

if isempty(schedule)
    error('Could not find valid Study 2 schedule. Expected 18 trials and agents 1, 2.');
end

agent  = schedule.agent;
effort = schedule.effort;
reward = schedule.reward;

fprintf('Schedule check:\n');
disp(tabulate(agent));

%% Storage

results_rows = {};
confusion_BIC = zeros(nModels, nModels);  % rows = simulated, columns = recovered
confusion_XP  = zeros(nModels, nModels);

all_fit_tables = cell(nRounds, nModels);

%% Main loop

for gen_m = 1:nModels

    gen_model = models{gen_m};

    fprintf('\n============================================================\n');
    fprintf('Generating model: %s\n', gen_model);
    fprintf('============================================================\n');

    for r = 1:nRounds

        fprintf('\nRound %d of %d for generating model %s\n', r, nRounds, gen_model);

        rng(1000 + gen_m*100 + r)

        %% Simulate dataset from generating model

        s_sim.PM.expname = sprintf('MI_%s_round_%02d', gen_model, r);
        s_sim.PM.ID      = cell(1, nSubj);
        s_sim.PM.beh     = cell(1, nSubj);
        s_sim.PM.em      = struct();

        gen_params = get_params(gen_model);
        nParams = numel(gen_params);

        true_param_mat = nan(nSubj, nParams);

        for is = 1:nSubj

            true_params = nan(1, nParams);

            for p = 1:nParams
                pname = gen_params{p};

                if contains(pname, 'k')
                    true_params(p) = k_range(1) + rand * diff(k_range);

                elseif contains(pname, 'beta')
                    true_params(p) = beta_range(1) + rand * diff(beta_range);

                else
                    error('Unknown parameter type: %s', pname);
                end
            end

            true_param_mat(is,:) = true_params;

            p_work = simulate_choice_probs_study2( ...
                effort, reward, agent, true_params, gen_model);

            sim_choice = double(rand(size(p_work)) < p_work);

            Tsim = schedule;
            Tsim.choice = sim_choice;

            s_sim.PM.ID{is}  = sprintf('sim_%03d', is);
            s_sim.PM.beh{is} = table2struct(Tsim);
        end

        %% Fit all candidate models to this simulated dataset

        allfits = cell(1, nModels);

        for fit_m = 1:nModels

            fit_model = models{fit_m};

            fprintf('Fitting model %d/%d: %s\n', fit_m, nModels, fit_model);

            rng(2000 + gen_m*1000 + r*100 + fit_m)

            allfits{fit_m} = EMfit_ms_par(s_sim.PM, fit_model, bounds);

            s_sim.PM.em.(fit_model) = allfits{fit_m}.(fit_model);
        end

        %% Compute BICint for each fitted model

        bicint = nan(nModels,1);

        for fit_m = 1:nModels

            fit_model = models{fit_m};

            fprintf('Computing BICint for %s\n', fit_model);

            rng(3000 + gen_m*1000 + r*100 + fit_m)

            bicint(fit_m) = cal_BICint_ms(s_sim.PM, fit_model, bounds);

            s_sim.PM.em.(fit_model).fit.bicint = bicint(fit_m);
        end

        %% Compute LME matrix and XP

        lme = nan(nSubj, nModels);

        for fit_m = 1:nModels
            fit_model = models{fit_m};
            lme(:, fit_m) = s_sim.PM.em.(fit_model).fit.lme(:);
        end

        valid = all(isfinite(lme), 2);

        if sum(valid) < 5
            warning('Very few valid subjects for BMS in gen %s round %d.', gen_model, r);
            xp = nan(nModels,1);
        else
            [~,~,xp] = spm_BMS(lme(valid,:));
            xp = xp(:);
        end

        %% Select winners

        [~, winner_BIC] = min(bicint);
        [~, winner_XP]  = max(xp);

        confusion_BIC(gen_m, winner_BIC) = confusion_BIC(gen_m, winner_BIC) + 1;
        confusion_XP(gen_m, winner_XP)   = confusion_XP(gen_m, winner_XP) + 1;

        %% Store fit table

        relBIC = bicint - min(bicint);
        sumLME = sum(lme(valid,:), 1, 'omitnan')';

        fit_table = table( ...
            string(models(:)), ...
            sumLME, ...
            bicint, ...
            relBIC, ...
            xp, ...
            'VariableNames', {'estimated_model','sumLME','bicint','relBIC','xp'} ...
        );

        fit_table.simulated_model = repmat(string(gen_model), nModels, 1);
        fit_table.round = repmat(r, nModels, 1);
        fit_table = movevars(fit_table, {'simulated_model','round'}, 'Before', 'estimated_model');

        all_fit_tables{r, gen_m} = fit_table;

        for fit_m = 1:nModels
            results_rows(end+1,:) = { ...
                gen_model, ...
                r, ...
                models{fit_m}, ...
                sumLME(fit_m), ...
                bicint(fit_m), ...
                relBIC(fit_m), ...
                xp(fit_m), ...
                winner_BIC == fit_m, ...
                winner_XP == fit_m ...
            };
        end

        fprintf('Winner by BICint: %s\n', models{winner_BIC});
        fprintf('Winner by XP:     %s\n', models{winner_XP});

    end
end

%% Convert result tables

results_table = cell2table(results_rows, ...
    'VariableNames', {'simulated_model','round','estimated_model', ...
                      'sumLME','bicint','relBIC','xp', ...
                      'winner_by_BIC','winner_by_XP'});

confusion_BIC_table = array2table(confusion_BIC, ...
    'VariableNames', matlab.lang.makeValidName(models), ...
    'RowNames', models);

confusion_XP_table = array2table(confusion_XP, ...
    'VariableNames', matlab.lang.makeValidName(models), ...
    'RowNames', models);

disp('Confusion matrix, winner by BICint:')
disp(confusion_BIC_table)

disp('Confusion matrix, winner by XP:')
disp(confusion_XP_table)

%% Save outputs

writetable(results_table, ...
    fullfile(sim_output_dir, 'model_identifiability_study2_results_long.csv'));

writetable(confusion_BIC_table, ...
    fullfile(sim_output_dir, 'model_identifiability_study2_confusion_BICint.csv'), ...
    'WriteRowNames', true);

writetable(confusion_XP_table, ...
    fullfile(sim_output_dir, 'model_identifiability_study2_confusion_XP.csv'), ...
    'WriteRowNames', true);

save(fullfile(sim_output_dir, ['model_identifiability_study2_', date, '.mat']), ...
    'models', 'nRounds', 'nSubj', ...
    'results_table', 'confusion_BIC', 'confusion_XP', ...
    'confusion_BIC_table', 'confusion_XP_table', ...
    'all_fit_tables');

fprintf('\nSaved model identifiability outputs to:\n%s\n', sim_output_dir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOCAL HELPER FUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function p_work = simulate_choice_probs_study2(effort, reward, agent, params, modelID)

    % --- k parameters ---
    if contains(modelID,'one_k')
        discount = params(1) * ones(size(agent));
        beta_idx = 2;

    elseif contains(modelID,'two_k')
        discount = (agent==1).*params(1) + ...
                   (agent==2).*params(2);
        beta_idx = 3;

    elseif contains(modelID,'three_k')
        discount = (agent==1).*params(1) + ...
                   (agent==2).*params(2) + ...
                   (agent==3).*params(3);
        beta_idx = 4;

    elseif ~contains(modelID,'k')
        discount = zeros(size(agent));
        beta_idx = 1;

    else
        error('Cannot determine number of k parameters from model name: %s', modelID);
    end

    % --- beta parameters ---
    if contains(modelID,'one_beta')
        beta = params(beta_idx) * ones(size(agent));

    elseif contains(modelID,'two_beta')
        beta = (agent==1).*params(beta_idx) + ...
               (agent==2).*params(beta_idx+1);

    elseif contains(modelID,'three_beta')
        beta = (agent==1).*params(beta_idx) + ...
               (agent==2).*params(beta_idx+1) + ...
               (agent==3).*params(beta_idx+2);

    else
        error('Cannot determine number of beta parameters from model name: %s', modelID);
    end

    % --- subjective value of work ---
    if contains(modelID,'linear')
        SV_work = reward - (discount .* effort);

    elseif contains(modelID,'hyperbolic')
        SV_work = reward ./ (1 + (discount .* effort));

    else
        SV_work = reward - (discount .* (effort.^2));  % parabolic
    end

    % --- rest baseline ---
    SV_rest = 1;

    % --- softmax comparing work vs rest ---
    z = beta .* (SV_work - SV_rest);
    z = max(min(z, 35), -35);

    p_work = 1 ./ (1 + exp(-z));
    p_work = max(min(p_work, 1-1e-12), 1e-12);
end