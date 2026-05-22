function params = get_params(modelID)
%GET_PARAMS  Return ordered parameter names for a given modelID.
% Handles patterns like:
%   ms_three_k_one_beta_linear
%   three_k_three_beta_hyperbolic
%   two_k_two_beta, etc.
%
% Output order: all k's first, then beta(s).

% normalise
id = lower(string(modelID));

% --- detect K count ---
if contains(id, "three_k")
    kparams = {'k_agent1','k_agent2','k_agent3'};
elseif contains(id, "two_k")
    kparams = {'k_agent1','k_agent2'};
elseif contains(id, "one_k")
    kparams = {'k'};
elseif contains(id, "_k")
    % pattern mentions k but not recognised as one/two/three
    error('get_params: cannot determine K count from modelID: %s', modelID);
else
    kparams = {}; % models without effort discounting
end

% --- detect beta count ---
if contains(id, "three_beta")
    betaparams = {'beta_agent1','beta_agent2','beta_agent3'};
elseif contains(id, "two_beta")
    betaparams = {'beta_agent1','beta_agent2'};
elseif contains(id, "one_beta")
    betaparams = {'beta'};
else
    error('get_params: cannot determine beta count from modelID: %s', modelID);
end

% --- assemble in fixed order (k's, then betas) ---
params = [kparams, betaparams];

% sanity: non-empty if model should have parameters
if isempty(params)
    error('get_params: no parameters inferred for modelID: %s', modelID);
end
end
