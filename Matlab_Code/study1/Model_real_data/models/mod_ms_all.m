function [fval,fit] = mod_ms_all(behavData, q, fitop, modelID, bounds, varargin)

if nargin > 5
    prior = varargin{1};
end

% parameter names
params = get_params(modelID);

% transform from Gaussian space
qt = nan(1,numel(params));
for p = 1:numel(params)
    qt(p) = norm2positive(q(p), [bounds.lower(p), bounds.upper(p)]);
end

% data
chosen = [behavData.choice]';   % 1=work/accept, 0=rest/reject, others/NaN=missing
effort = [behavData.effort]';
reward = [behavData.reward]';   % reward level for WORK option (here: 2,3,4)
agent  = [behavData.agent]';

% valid trials
valid = (chosen==0 | chosen==1);

% --- k parameters ---
if contains(modelID,'one_k')
    discount = qt(1) * ones(size(agent));
    beta_idx = 2;
elseif contains(modelID,'two_k')
    discount = (agent==1).*qt(1) + (agent==2).*qt(2);
    beta_idx = 3;
elseif contains(modelID,'three_k')
    discount = (agent==1).*qt(1) + (agent==2).*qt(2) + (agent==3).*qt(3);
    beta_idx = 4;
elseif ~contains(modelID,'k')
    discount = zeros(size(agent));
    beta_idx = 1;
else
    error(['Cannot determine number of k parameters from model name: ', modelID]);
end

% --- beta parameters ---
if contains(modelID,'one_beta')
    beta = qt(beta_idx) * ones(size(agent));
elseif contains(modelID,'two_beta')
    beta = (agent==1).*qt(beta_idx) + (agent==2).*qt(beta_idx+1);
elseif contains(modelID,'three_beta')
    beta = (agent==1).*qt(beta_idx) + (agent==2).*qt(beta_idx+1) + (agent==3).*qt(beta_idx+2);
else
    error(['Cannot determine number of beta parameters from model name: ', modelID]);
end

% --- subjective value of WORK offer ---
if contains(modelID,'linear')
    SV_work = reward - (discount .* effort);
elseif contains(modelID,'hyperbolic')
    SV_work = reward ./ (1 + (discount .* effort));
else
    SV_work = reward - (discount .* (effort.^2));   % parabolic
end

% --- baseline REST offer ---
% In your task, REST always yields 3 credits, which corresponds to reward level 1.
SV_rest = 1;

% --- softmax comparing WORK vs REST ---
z = beta .* (SV_work - SV_rest);
z = max(min(z,35),-35);                  % clip
p_work = 1 ./ (1 + exp(-z));             % logistic
p_work = max(min(p_work,1-1e-12),1e-12);

% probability of observed choice
p_chosen = nan(size(p_work));
p_chosen(chosen==1) = p_work(chosen==1);
p_chosen(chosen==0) = 1 - p_work(chosen==0);

% negative log-likelihood on valid trials only
nll = -sum(log(p_chosen(valid)));

if fitop.doprior == 0
    fval = nll;
else
    fval = -(-nll + prior.logpdf(q));
end

if fitop.dofit == 1
    fit = struct;
    fit.xnames     = params;
    fit.choiceprob = p_chosen(:);   % prob of observed choice per trial
    fit.mat        = SV_work(:);    % keep as work SV for consistency with prior code
    fit.names      = {'SV_work'};
else
    fit = [];
end
end