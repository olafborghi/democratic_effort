%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  
% -----------------------------------------------------------------------------------------
%MATLAB Version: 25.2.0.3150157 (R2025b) Update 4
%Operating System: macOS  Version: 26.3 Build: 25D125 
%Java Version: Java 11.0.30+7-LTS with Amazon.com Inc. OpenJDK 64-Bit Server VM mixed mode
%-----------------------------------------------------------------------------------------
%MATLAB                                                Version 25.2        (R2025b)                
%Econometrics Toolbox                                  Version 25.2        (R2025b)                
%FieldTrip                                             Version unknown     www.fieldtriptoolbox.org
%Optimization Toolbox                                  Version 25.2        (R2025b)                
%RICOH MEG Reader toolbox for MATLAB                   Version 1.0.2                               
%Statistical Parametric Mapping                        Version 7771        (SPM12)                 
%Statistics and Machine Learning Toolbox               Version 25.2        (R2025b)                
%Yokogawa MEG Reader toolbox for MATLAB                Version 1.5.1      
% 
% 
% 
% Unified pipeline for Democratic Effort Task modelling
%
% - Imports trial-level CSV files
% - Recode agent column (VOTEALL→1, VOTERURAL→2, VOTEURBAN→3)
% - Standardises column names to match toolbox: effort, reward, choice
% - Builds struct 's' in the format expected by EM fitting functions
% - Fits models using EM
% - Saves outputs for model comparison and parameter extraction
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all
clc
clearvars
addpath('/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/Model_real_data/models');
addpath('/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/Model_real_data/tools');

spm_dir = '/Users/marianavonmohr/Desktop/spm12';

if ~isfolder(spm_dir)
    error('SPM folder not found: %s', spm_dir);
end


%%% spm fix %%%%
spm_dir = '/Users/marianavonmohr/Desktop/spm12';

if ~isfolder(spm_dir)
    error('SPM folder not found: %s', spm_dir);
end

addpath(spm_dir);
addpath(fullfile(spm_dir,'src'));
savepath;

rehash;
clear functions;

if exist('spm_BMS','file') ~= 2
    error('spm_BMS not found on MATLAB path. Check your SPM installation.');
end

gamrnd_path = which('spm_gamrnd');
if isempty(gamrnd_path)
    error('spm_gamrnd not found on MATLAB path.');
end

disp(['spm_BMS found at: ' which('spm_BMS')]);
disp(['spm_gamrnd found at: ' gamrnd_path]);
%% Step 1: Import trial-level CSV files and build struct 's'

dataFolder = '/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/Model_real_data/no_na';

if ~isfolder(dataFolder)
    error('Folder not found: %s', dataFolder);
end

files = dir(fullfile(dataFolder,'*.csv'));
fprintf('Found %d CSV files in %s\n', numel(files), dataFolder);

N = numel(files);
s.PM.ID  = cell(1,N);
s.PM.beh = cell(1,N);

for i = 1:N
    [~,name] = fileparts(files(i).name);
    pid = split(name,'_'); 
    pid = pid{1};
    s.PM.ID{i} = pid;

    T = readtable(fullfile(files(i).folder, files(i).name));

    % Recode agent column for 3 agents
    if ismember('agent', T.Properties.VariableNames)
        T.agent = strrep(T.agent, 'VOTEALL',   '1');
        T.agent = strrep(T.agent, 'VOTERURAL', '2');
        T.agent = strrep(T.agent, 'VOTEURBAN', '3');
        T.agent = str2double(T.agent);
    end

    % Standardise column names
    T.Properties.VariableNames = strrep(T.Properties.VariableNames,'eff','effort');
    T.Properties.VariableNames = strrep(T.Properties.VariableNames,'rew','reward');
    T.Properties.VariableNames = strrep(T.Properties.VariableNames,'decision','choice');

    % Convert to struct array
    s.PM.beh{i} = table2struct(T);
end

save('/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/Model_real_data/full_democraticeffortdata_for_model.mat','s');


disp('--- Sanity check ---');
disp(s.PM.ID{1});
disp(struct2table(s.PM.beh{1}(1:5)));

%% Step 2: Prepare modelling setup

include    = 'full_democraticeffortdata';
file_name  = [include, '_for_model'];
load([file_name]);  % loads 's'

e = 'PM';
s.(e).expname = 'DemocraticEffort';
s.(e).em = {};

bounds.beta = [0, 10];
kdetails    = 'var';

output_dir = '/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/PM_R_code/data/';

M.dofit = 1;
M.doMC  = 1;


M.modid = { ...
    % Three-agent models
    'ms_three_k_one_beta', 'ms_three_k_one_beta_linear', 'ms_three_k_one_beta_hyperbolic', ...
    'ms_three_k_three_beta', 'ms_three_k_three_beta_linear', 'ms_three_k_three_beta_hyperbolic'};

fitMeasures = {'lme','bicint','xp','pseudoR2','choiceProbMedianR2'};
criteria    = 'bicint';

%% Step 3: Run EM fitting

if M.dofit
    for im = 1:numel(M.modid)
        if ~isfield(s.(e).em,(M.modid{im}))
            rng default
            dotry=1;
            while dotry
                close all;
                allfits{im} = EMfit_ms_par(s.(e),M.modid{im},bounds);
                dotry=0;
            end
        end
    end

    for im = 1:numel(M.modid)
        s.(e).em.(M.modid{im}) = allfits{1,im}.(M.modid{im});
    end

    save(fullfile('/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/Model_real_data/workspaces', ...
    ['EM_fit_results_', include, '_', date, '.mat']));

    
    parfor im = 1:numel(M.modid)
        rng default
        allbics{im} = cal_BICint_ms(s.(e),M.modid{im},bounds);
    end
    for im = 1:numel(M.modid)
        s.(e).em.(M.modid{im}).fit.bicint = allbics{1,im};
    end
end

%% Step 4: Compare models

if M.doMC
    rng default
    tmp = EMmc_ms(s.(e),M.modid);
s.(e).em = tmp.em;

    for im = 1:numel(M.modid)
        s.(e).em.(M.modid{im}).fit.pseudoR2 = pseudoR2(s.(e),M.modid{im},2,1);
        s.(e) = choiceProbR2(s.(e),M.modid{im},1);
    end
    [fits.(e),fitstab.(e)] = getfits(s.(e),fitMeasures,M.modid);
end

%% Step 5: Extract parameters from best model

switch criteria
    case {'xp','pseudoR2','choiceProbMedianR2'}
        bestmod = find(fitstab.(e).(criteria) == max(fitstab.(e).(criteria)));
    case {'lme','bicint'}
        bestmod = find(fitstab.(e).(criteria) == min(fitstab.(e).(criteria)));
end
bestname = M.modid{bestmod};
disp(['Extracting parameters from ', bestname,' based on best ',criteria]);


for i=1:length(s.(e).ID)
    IDs{i,1} = s.(e).ID{i};
end

params = getparams(s.(e), bestname, bounds, IDs);


%% Step 6: Save results


% Save subject-level parameter estimates
writetable(params.all_table, ...
    [output_dir,'EM_fit_parameters_',include,'_',bestname,'.csv'], ...
    'WriteRowNames',true);

% Save the workspace
workspace_dir = '/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/Model_real_data/workspaces';
save(fullfile(workspace_dir, ['EM_fit_results_', include, '_', date, '.mat']));

% Save model comparison statistics with model names
fit = fits.(e);
fit = [[1:numel(M.modid)]', fit];
fit(:,end+1) = fit(:,find(contains(fitMeasures,'bicint'))+1) - ...
               min(fit(:,find(contains(fitMeasures,'bicint'))+1));

% Add model names as first column
% Add model names as first column
fittabcell = [M.modid(:), num2cell(fit)];
fittabnum = cell2table(fittabcell, 'VariableNames', ...
    ['model_name', 'model_index', fitMeasures, 'relbic']);


% Write output
writetable(fittabnum, [output_dir, e, '_model_fit_statistics_', include, '.csv'], ...
    'WriteRowNames', true);

disp('--- Model fit table with model names saved successfully ---');




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MV additions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%% VERIFY WINNING MODEL AND FIT CONSISTENCY %%%%%%%%%%%%%%%%%%%

%% Load newest EM workspace (.mat only)
workspace_dir = '/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/Model_real_data/workspaces';
files = dir(fullfile(workspace_dir, 'EM_fit_results_full_democraticeffortdata*.mat'));
if isempty(files), error('No EM workspace .mat files found in %s', workspace_dir); end
[~, idx] = max([files.datenum]);
wsfile = fullfile(workspace_dir, files(idx).name);
load(wsfile, 's');   % must contain struct s
fprintf('Loaded workspace: %s\n', files(idx).name);

%% Define model set to verify (3-k space)
e = 'PM';
modnames = {
    'ms_three_k_one_beta', 'ms_three_k_one_beta_linear', 'ms_three_k_one_beta_hyperbolic', ...
    'ms_three_k_three_beta', 'ms_three_k_three_beta_linear', 'ms_three_k_three_beta_hyperbolic'};

% guard: ensure all models exist in s.PM.em
for i = 1:numel(modnames)
    if ~isfield(s.(e).em, modnames{i})
        error('Model %s not found in workspace', modnames{i});
    end
end

%% Build LME matrix with safe fallbacks; also collect per-subject BIC for proxy XP
nmods = numel(modnames);
nsubj = numel(s.(e).ID);
lme   = nan(nsubj, nmods);
bic   = nan(nsubj, nmods);  % per-subject BIC (for proxy XP only)

for im = 1:nmods
    M = s.(e).em.(modnames{im});

    % LME: use stored, else recompute via Laplace with ridge
    if isfield(M,'fit') && isfield(M.fit,'lme') && ~isempty(M.fit.lme)
        lme(:,im) = M.fit.lme(:);
    else
        L = nan(nsubj,1);
        for isub = 1:nsubj
            try
                H = M.hess(:,:,isub);
                H = (H + H')./2;
                lam = 1e-6; tries = 0; p = 1;
                while p ~= 0 && tries <= 6
                    [R,p] = chol(H + lam*eye(size(H)));
                    if p ~= 0, lam = lam*10; tries = tries+1; end
                end
                if p == 0
                    logdetH = 2*sum(log(diag(R)));
                    kpar    = size(H,1);
                    L(isub) = -M.fit.npl(isub) - 0.5*logdetH + (kpar/2)*log(2*pi);
                end
            catch
                % leave NaN
            end
        end
        lme(:,im) = L;
    end

    % per-subject BIC (optional; for XP-from-BIC proxy)
    if isfield(M,'fit') && isfield(M.fit,'bic') && ~isempty(M.fit.bic)
        bic(:,im) = M.fit.bic(:);
    end
end

valid = all(isfinite(lme), 2);
fprintf('Valid subjects for LME: %d of %d\n', sum(valid), nsubj);

%% Random-effects BMS on complete LME cases
if exist('spm_BMS','file') ~= 2
    error('spm_BMS not found on path. Add SPM12 to the MATLAB path.');
end
[~,~,xp] = spm_BMS(lme(valid,:));
xp = xp(:);

%% Summed LME on the SAME valid subjects; Integrated BIC (bicint) per model
sumLME = sum(lme(valid,:), 1, 'omitnan')';

bicint = nan(nmods,1);
for im = 1:nmods
    if isfield(s.(e).em.(modnames{im}).fit,'bicint')
        bicint(im) = s.(e).em.(modnames{im}).fit.bicint;  % integrated BIC scalar
    else
        bicint(im) = NaN;
    end
end
relBIC = bicint - min(bicint);

T = table(string(modnames(:)), sumLME, bicint, relBIC, xp, ...
    'VariableNames', {'model','sumLME','bicint','relBIC','xp_LME'});
T = sortrows(T, 'bicint');  % lower integrated BIC is better
disp(T);

% Pairwise ΔLME between the two best by integrated BIC
[~,ordBIC] = sort(bicint, 'ascend');
m1 = ordBIC(1); m2 = ordBIC(2);
dL = lme(valid,m2) - lme(valid,m1);
fprintf('Median ΔLME (%s - %s) = %.3f\n', modnames{m2}, modnames{m1}, median(dL,'omitnan'));

%% Cross-check: BIC-proxy XP (needs per-subject BIC)
if all(isfinite(bic(valid,:)), 'all')
    [~,~,xp_bic] = spm_BMS(-0.5 * bic(valid,:), [], 0, 0);
    xp_bic = xp_bic(:);
    Tbic = table(string(modnames(:)), xp, xp_bic, ...
        'VariableNames', {'model','xp_LME','xp_from_BICproxy'});
    disp(Tbic);
else
    warning('Per-subject BIC missing for some models; skipping XP-from-BIC proxy.');
end

%% Parameter bounds sanity check for the integrated-BIC winner
best_by_BIC = modnames{ordBIC(1)};
B = s.(e).em.(best_by_BIC);

if ~isfield(B.fit,'bounds') || ~isfield(B,'q') || ~isfield(B,'qnames')
    warning('Bounds or parameter arrays missing for %s. Skipping bounds check.', best_by_BIC);
else
    bnds   = B.fit.bounds;                 % has .lower and .upper
    q_norm = B.q;                          % subjects × params (Gaussian space)
    q_nat  = nan(size(q_norm));
    for p = 1:numel(bnds.lower)
        q_nat(:,p) = norm2positive(q_norm(:,p), [bnds.lower(p), bnds.upper(p)]);
    end
    withinLower = all(q_nat >= (bnds.lower - 1e-8), 1);
    withinUpper = all(q_nat <= (bnds.upper + 1e-8), 1);
    atLower     = mean(abs(q_nat - bnds.lower) < 1e-6, 1);
    atUpper     = mean(abs(q_nat - bnds.upper) < 1e-6, 1);

    S = table(string(B.qnames(:)), withinLower(:), withinUpper(:), atLower(:), atUpper(:), ...
        'VariableNames', {'param','all_ge_lower','all_le_upper','prop_at_lower','prop_at_upper'});
    disp(S);

    % quick summaries
    isK    = contains(B.qnames,'k');
    isBeta = contains(B.qnames,'beta');
    fprintf('k medians:   %s\n', mat2str(median(q_nat(:,isK),1)));
    fprintf('beta medians:%sx\n', mat2str(median(q_nat(:,isBeta),1)));
end

%% Save an XP-fixed copy of the workspace
tag = datestr(now, 'yyyymmdd_HHMM');
outname = fullfile(workspace_dir, ['EM_fit_results_full_democraticeffortdata_' tag '_XPfixed.mat']);
save(outname, 's');
fprintf('Saved XP-fixed workspace: %s\n', outname);



%%%%%%%%%%%%%%%%%%% EXTRACT AND SAVE PARAMETERS FOR FIXED WINNING MODEL %%%%%%%%%%%%%%%%%%%

% Choose the fixed winning model (by integrated BIC and verification steps)
%%% insert name of winning model
best_fixed = 'ms_three_k_one_beta_hyperbolic';

% Sanity check that this model exists in the workspace
if ~isfield(s.(e).em, best_fixed)
    error('Winning model %s not found in s.%s.em', best_fixed, e);
end

% Subject IDs as a column cell array (same format used in Step 5)
IDs = s.(e).ID(:);

% Use the SAME helper as Step 5 to ensure identical formatting and fields
params_fixed = getparams(s.(e), best_fixed, bounds, IDs);

% Save subject-level parameter estimates in the same format as Step 5
writetable(params_fixed.all_table, ...
    [output_dir, 'EM_fit_parameters_', include, '_', best_fixed, '.csv'], ...
    'WriteRowNames', true);

fprintf('Saved parameter table using getparams() for %s.\n', best_fixed);

% Optional: also persist the updated workspace state
save(fullfile(workspace_dir, ['EM_fit_results_', include, '_', date, '.mat']), 's');   


% --- Write a labelled version with explicit agent names ---
T = params_fixed.all_table;                 % columns: ID,k_agent1,k_agent2,k_agent3,beta (order may vary)
vn = T.Properties.VariableNames;

% Reorder to a standard layout if needed
want = {'ID','k_agent1','k_agent2','k_agent3','beta'};
[tf,loc] = ismember(want, vn);
if all(tf)
    T = T(:, loc);
    vn = want;
end

% Rename k columns to agent labels
map_old = {'k_agent1','k_agent2','k_agent3'};
map_new = {'all_k','rural_k','urban_k'};
for i = 1:numel(map_old)
    idx = find(strcmp(vn, map_old{i}));
    if ~isempty(idx), vn{idx} = map_new{i}; end
end
T.Properties.VariableNames = vn;

% Ensure ID is text, not categorical
if ~isstring(T.ID) && ~ischar(T.ID)
    T.ID = string(T.ID);
end

% Save labelled file
writetable(T, [output_dir, 'EM_fit_parameters_', include, '_', best_fixed, '_labeled.csv'], ...
    'WriteRowNames', false);

fprintf('Saved labelled parameter table for %s.\n', best_fixed); 



%%%% double check whether XP is genuine %%%%%%%%%%

valid = all(isfinite(lme),2);
[alpha, exp_r, xp, pxp, bor] = spm_BMS(lme(valid,:));

disp(alpha)
disp(exp_r)
disp(xp)
disp(pxp)
disp(bor)

%%% at the individual level %%%%
[~, best_per_subject] = max(lme, [], 2);
counts = accumarray(best_per_subject, 1, [numel(modnames), 1]);
perc = 100 * counts / sum(counts);

for i = 1:numel(modnames)
    fprintf('%s: %d subjects (%.2f%%)\n', modnames{i}, counts(i), perc(i));
end