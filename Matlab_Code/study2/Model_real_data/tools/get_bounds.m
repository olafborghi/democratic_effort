% NOTE (MvM 2025): Works with Democratic Effort Task.
% Updated to handle models with three agents (three k parameters and/or three betas).
% maxValue() was already adapted earlier to handle struct arrays of trials 
% with fields effort and reward.

function [bounds] = get_bounds(s, modelID, bounds)

% Set k bounds if not already passed in
if ~isfield(bounds, 'k') && contains(modelID, 'k')
    bounds.k = [0, maxValue(s, 'k', modelID)];
end

% Handle number of k parameters
if contains(modelID, 'one_k')
    lbk = bounds.k(1);
    ubk = bounds.k(2);
elseif contains(modelID, 'two_k')
    lbk = [bounds.k(1), bounds.k(1)];
    ubk = [bounds.k(2), bounds.k(2)];
elseif contains(modelID, 'three_k')
    lbk = [bounds.k(1), bounds.k(1), bounds.k(1)];
    ubk = [bounds.k(2), bounds.k(2), bounds.k(2)];
else
    error(['Cant`t determine number of k parameters from model name: ', modelID])
end

% Handle number of beta parameters
if contains(modelID, 'one_beta')
    lbbeta = bounds.beta(1);
    ubbeta = bounds.beta(2);
elseif contains(modelID, 'two_beta')
    lbbeta = [bounds.beta(1), bounds.beta(1)];
    ubbeta = [bounds.beta(2), bounds.beta(2)];
elseif contains(modelID, 'three_beta')
    lbbeta = [bounds.beta(1), bounds.beta(1), bounds.beta(1)];
    ubbeta = [bounds.beta(2), bounds.beta(2), bounds.beta(2)];
else
    error(['Cant`t determine number of beta parameters from model name: ', modelID])
end

% Final bounds vectors
bounds.lower = [lbk, lbbeta];   % lower bounds on parameters
bounds.upper = [ubk, ubbeta];   % upper bounds on parameters

end
