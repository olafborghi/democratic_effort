function [nll,aic,bic] =mk_0mod(ntrials,nopt)
% gives model fit for chance model for a given subject
% INPUT:       - ntrials:  number of trials (assuming that a choice was made on each trial
%              - nopt:     number of options choosable per trial
% OUTPUT:      - nll, aic, bic

% NOTE (MvM 2025): Since this is a pure chance model with no free parameters (k = 0),
% AIC and BIC both reduce to 2*nll. That's why they are identical here.

ChoiceProb = repmat(1/nopt,ntrials,1);

nll = -sum(log(ChoiceProb));
aic = 2*nll;
bic = 2*nll;

end



