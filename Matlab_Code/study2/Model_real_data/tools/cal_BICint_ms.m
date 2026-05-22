function [bicint] = cal_BICint_ms(rootfile, modelID, bounds, Nsample)
% calculates BICint
% MK Wittmann, 2017

mroot = rootfile.em;
bounds = get_bounds(rootfile, modelID, bounds);

% define settings
if nargin < 4
    Nsample = 2000;
end

% dont do prior, just get the NLL
fit.dofit   = 0;
fit.doprior = 0;
fit.objfunc = str2func('mod_ms_all');
fit.npar    = size(mroot.(modelID).q, 2);
fit.ntrials = mroot.(modelID).ntrials;
fit.beh     = mroot.(modelID).behaviour;

% info for normpdf, and flip if it is the wrong orientation
mu        = mroot.(modelID).gauss.mu;
if size(mu,2) > size(mu,1), mu = mu'; end

sigmasqrt = sqrt(mroot.(modelID).gauss.sigma);
if size(sigmasqrt,2) > size(sigmasqrt,1), sigmasqrt = sigmasqrt'; end

% collect integrated nll
iLog = nan(numel(fit.beh),1);

%% start computing
fprintf('%s - computing BICint: ', modelID);

for is = 1:numel(fit.beh)

   subnll   = nan(1, Nsample);
   Gsamples = normrnd(repmat(mu,1,Nsample), repmat(sigmasqrt,1,Nsample));

   for k = 1:Nsample
      subnll(k) = fit.objfunc(fit.beh{is}, Gsamples(:,k), fit, modelID, bounds, fit.doprior);
   end

   if mod(is,100) == 0
       fprintf('%d,', is);
   end

   % numerically stable log(mean(exp(-subnll)))
   m = min(subnll);
   iLog(is) = -m + log(mean(exp(-(subnll - m))));
end

%% Compute BICint
bicint = -2 * sum(iLog) + fit.npar * log(sum(fit.ntrials));

fprintf(' final BICint = %.3f\n', bicint);

end



