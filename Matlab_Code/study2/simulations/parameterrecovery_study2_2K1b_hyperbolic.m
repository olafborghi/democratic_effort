%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARAMETER RECOVERY, STUDY 2
% Winning model: ms_two_k_one_beta_hyperbolic
%
% This script:
% 1. Loads the empirical Study 2 workspace
% 2. Checks that the loaded workspace contains the Study 2 18-trial schedule
% 3. Simulates choices from known grid-based parameters
% 4. Fits the winning model back to the simulated data using hierarchical EM
% 5. Compares true vs recovered parameters
% 6. Saves all outputs to:
%    /Users/marianavonmohr/Desktop/Effort_computationalmodels/study2/simulations
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

e       = 'PM';
modelID = 'ms_two_k_one_beta_hyperbolic';

bounds.beta = [0, 10];

%% Load fitted empirical Study 2 workspace

files = dir(fullfile(workspace_dir, 'EM_fit_results_full_democraticeffortdata*.mat'));

if isempty(files)
    error('No Study 2 EM workspace found in %s', workspace_dir);
end

[~, idx] = max([files.datenum]);
wsfile = fullfile(workspace_dir, files(idx).name);

load(wsfile, 's');

fprintf('Loaded empirical workspace: %s\n', files(idx).name);

if ~isfield(s.(e).em, modelID)
    error('Winning model %s not found in workspace.', modelID);
end

%% Check loaded workspace is Study 2

fprintf('\nChecking first 10 participants in loaded workspace:\n');

for i = 1:min(10, numel(s.(e).beh))
    Tcheck = struct2table(s.(e).beh{i});

    if ismember('agent', Tcheck.Properties.VariableNames)
        fprintf('%s: %d trials, agents = [%s]\n', ...
            s.(e).ID{i}, height(Tcheck), num2str(sort(unique(Tcheck.agent))'));
    else
        fprintf('%s: %d trials, agent column missing\n', ...
            s.(e).ID{i}, height(Tcheck));
    end
end

%% Get bounds from empirical winning model

B = s.(e).em.(modelID);

% Use the exact fitted bounds from the empirical winning model
bounds_full = B.fit.bounds;

disp('Using bounds from empirical winning model:')
disp(bounds_full)

%% Use empirical Study 2 task schedule

% Study 2 should have 18 trials:
% 2 beneficiaries × 3 effort levels × 3 reward levels
% agents: 1 = rural, 2 = urban

schedule = [];

for isub = 1:numel(s.(e).beh)

    Ttmp = struct2table(s.(e).beh{isub});

    if all(ismember({'agent','effort','reward','choice'}, Ttmp.Properties.VariableNames))

        n_trials = height(Ttmp);
        agents_present = sort(unique(Ttmp.agent));

        if n_trials == 18 && isequal(agents_present(:), [1;2])
            schedule = Ttmp;

            fprintf('\nUsing schedule from subject %s with %d trials and agents [%s].\n', ...
                s.(e).ID{isub}, n_trials, num2str(agents_present(:)'));

            break
        end
    end
end

if isempty(schedule)
    error(['Could not find a valid Study 2 schedule. Expected 18 trials and agents 1, 2. ', ...
           'Check that the loaded workspace is really Study 2.']);
end

agent  = schedule.agent;
effort = schedule.effort;
reward = schedule.reward;

nTrials = height(schedule);

fprintf('Using %d trials from empirical Study 2 schedule.\n', nTrials);
disp(tabulate(agent));

%% Define true parameter grid

% Study 2 winning model is 2K1β:
% k_agent1 = rural
% k_agent2 = urban
% beta     = shared inverse temperature
%
% Following the Study 1 recovery logic:
% K values across parameter space, beta as integers 0 to 10.
%
% For 2K1β:
% 4 K values for each of 2 K parameters and 11 beta values
% gives 4 × 4 × 11 = 176 simulated agents.

k_grid    = [0, 0.3, 0.6, 0.9];
beta_grid = 0:1:10;

% Make sure grid is within bounds
if any(k_grid < bounds_full.lower(1)) || any(k_grid > bounds_full.upper(1))
    error('k_grid values fall outside fitted k bounds.');
end

if any(beta_grid < bounds_full.lower(3)) || any(beta_grid > bounds_full.upper(3))
    error('beta_grid values fall outside fitted beta bounds.');
end

[K1, K2, BETA] = ndgrid(k_grid, k_grid, beta_grid);

true_params = [K1(:), K2(:), BETA(:)];

param_names = {'k_agent1','k_agent2','beta'};
nSimSubj = size(true_params, 1);

fprintf('Simulating %d artificial agents.\n', nSimSubj);

%% Add small noise to true parameters

noise_sd = 0.05;

true_params_noisy = true_params;

for p = 1:numel(param_names)

    lower_p = bounds_full.lower(p);
    upper_p = bounds_full.upper(p);

    for isub = 1:nSimSubj

        proposed = true_params(isub,p) + noise_sd * randn;

        % Resample until inside bounds
        while proposed < lower_p || proposed > upper_p
            proposed = true_params(isub,p) + noise_sd * randn;
        end

        true_params_noisy(isub,p) = proposed;
    end
end

%% Simulate choices

s_pr.PM.expname = 'ParameterRecoveryStudy2';
s_pr.PM.ID      = cell(1, nSimSubj);
s_pr.PM.beh     = cell(1, nSimSubj);
s_pr.PM.em      = struct();

for isub = 1:nSimSubj

    k1   = true_params_noisy(isub,1);   % rural
    k2   = true_params_noisy(isub,2);   % urban
    beta = true_params_noisy(isub,3);   % shared beta

    discount = (agent == 1).*k1 + ...
               (agent == 2).*k2;

    % Match mod_ms_all hyperbolic implementation
    SV_work = reward ./ (1 + discount .* effort);

    % Baseline rest option: 3 credits, coded as reward level 1
    SV_rest = 1;

    % Softmax comparing work vs rest
    z = beta .* (SV_work - SV_rest);
    z = max(min(z, 35), -35);

    p_work = 1 ./ (1 + exp(-z));
    p_work = max(min(p_work, 1-1e-12), 1e-12);

    sim_choice = double(rand(size(p_work)) < p_work);

    Tsim = schedule;
    Tsim.choice = sim_choice;

    s_pr.PM.ID{isub}  = sprintf('sim_%03d', isub);
    s_pr.PM.beh{isub} = table2struct(Tsim);
end

fprintf('Finished simulating choices.\n');

%% Fit same model to simulated data using hierarchical EM

fprintf('Fitting parameter recovery model: %s\n', modelID);

rng(456)
fit_pr = EMfit_ms_par(s_pr.PM, modelID, bounds);

s_pr.PM.em.(modelID) = fit_pr.(modelID);

fprintf('Finished EM fit for parameter recovery.\n');

%% Extract recovered parameters

IDs = s_pr.PM.ID(:);

params_rec = getparams(s_pr.PM, modelID, bounds, IDs);

recovered_params = params_rec.q_nat;

%% Build output table

recovery_table = table();

recovery_table.ID = string(IDs);

recovery_table.true_rural_k = true_params_noisy(:,1);
recovery_table.true_urban_k = true_params_noisy(:,2);
recovery_table.true_beta    = true_params_noisy(:,3);

recovery_table.recovered_rural_k = recovered_params(:,1);
recovery_table.recovered_urban_k = recovered_params(:,2);
recovery_table.recovered_beta    = recovered_params(:,3);

%% Parameter recovery correlations

true_mat = true_params_noisy;
rec_mat  = recovered_params;

pearson_r  = nan(numel(param_names),1);
pearson_p  = nan(numel(param_names),1);
spearman_r = nan(numel(param_names),1);
spearman_p = nan(numel(param_names),1);

for p = 1:numel(param_names)

    [rP, pP] = corr(true_mat(:,p), rec_mat(:,p), ...
        'Type', 'Pearson', 'Rows', 'complete');

    [rS, pS] = corr(true_mat(:,p), rec_mat(:,p), ...
        'Type', 'Spearman', 'Rows', 'complete');

    pearson_r(p)  = rP;
    pearson_p(p)  = pP;
    spearman_r(p) = rS;
    spearman_p(p) = pS;
end

recovery_summary = table( ...
    string(param_names(:)), ...
    pearson_r, pearson_p, ...
    spearman_r, spearman_p, ...
    'VariableNames', {'parameter','pearson_r','pearson_p','spearman_r','spearman_p'} ...
);

disp('Parameter recovery summary:')
disp(recovery_summary)

%% Cross-parameter confusion matrix

confusion = nan(numel(param_names)^2, 3);
row = 1;

for p_true = 1:numel(param_names)
    for p_rec = 1:numel(param_names)

        confusion(row,1) = p_true;
        confusion(row,2) = p_rec;
        confusion(row,3) = corr(true_mat(:,p_true), rec_mat(:,p_rec), ...
            'Type', 'Pearson', 'Rows', 'complete');

        row = row + 1;
    end
end

confusion_table = array2table(confusion, ...
    'VariableNames', {'simulated_parameter_index','recovered_parameter_index','pearson_r'});

confusion_table.simulated_parameter = string(param_names(confusion_table.simulated_parameter_index))';
confusion_table.recovered_parameter = string(param_names(confusion_table.recovered_parameter_index))';

confusion_table = movevars(confusion_table, ...
    {'simulated_parameter','recovered_parameter'}, ...
    'Before', 'simulated_parameter_index');

disp('Cross-parameter recovery matrix:')
disp(confusion_table)

%% Save outputs

writetable(recovery_table, ...
    fullfile(sim_output_dir, 'parameter_recovery_study2_2K1B_true_vs_recovered.csv'));

writetable(recovery_summary, ...
    fullfile(sim_output_dir, 'parameter_recovery_study2_2K1B_summary.csv'));

writetable(confusion_table, ...
    fullfile(sim_output_dir, 'parameter_recovery_study2_2K1B_confusion_matrix.csv'));

save(fullfile(sim_output_dir, ['parameter_recovery_study2_2K1B_', date, '.mat']), ...
    's_pr', 'true_params', 'true_params_noisy', 'recovered_params', ...
    'recovery_table', 'recovery_summary', 'confusion_table');

fprintf('Saved parameter recovery outputs to:\n%s\n', sim_output_dir);

%% Plot true vs recovered parameters

fig = figure('Color','w','Name','Study 2 parameter recovery');

labels_true = {'True rural K','True urban K','True beta'};
labels_rec  = {'Recovered rural K','Recovered urban K','Recovered beta'};

for p = 1:numel(param_names)

    subplot(1,3,p)

    scatter(true_mat(:,p), rec_mat(:,p), 20, 'filled')
    hold on
    lsline

    xlabel(labels_true{p})
    ylabel(labels_rec{p})
    title(sprintf('%s: r = %.2f', param_names{p}, pearson_r(p)))

    box off
end

exportgraphics(fig, ...
    fullfile(sim_output_dir, 'parameter_recovery_study2_2K1B_scatterplots.png'), ...
    'Resolution', 300);

fprintf('Saved recovery plot to:\n%s\n', sim_output_dir);