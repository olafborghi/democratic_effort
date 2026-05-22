function [modout]= EMfit_ms_par(rootfile, modelID, bounds)

qfit = 0;

fprintf([rootfile.expname ': Fitting ' modelID ' using EM.']);

modout      = rootfile.em;
n_subj      = length(rootfile.beh);
bounds      = get_bounds(rootfile, modelID, bounds);

%% Number of trials per subject
fit.ntrials = nan(n_subj,1);
for is = 1:n_subj
    fit.ntrials(is) = numel(rootfile.beh{is});
end

%% Model setup
fit.convCrit = 1e-3;
if qfit==1
    fit.convCrit = .5;
end

fit.maxit   = 800;
fit.npar    = get_npar(modelID);
fit.objfunc = str2func('mod_ms_all');
fit.doprior = 1;
fit.dofit   = 0;

fit.options = optimoptions(@fminunc,'Display','off','TolX',.0001,'Algorithm','quasi-newton');

if isfield(fit,'maxEvals')
    fit.options = optimoptions(@fminunc,'Display','off','TolX',.0001,...
        'MaxFunEvals', fit.maxEvals,'Algorithm','quasi-newton');
end

%% Initialise group priors
posterior.mu    = abs(.1.*randn(fit.npar,1));
posterior.sigma = repmat(100,fit.npar,1);

nextbreak = 0;
NPL       = [];
NPL_old   = -Inf;
NLPrior   = [];

%% ======================= EM FITTING =======================
for iiter = 1:fit.maxit

   m = [];
   h = [];

   prior.mu      = posterior.mu;
   prior.sigma   = posterior.sigma;
   prior.logpdf  = @(x) sum(log(normpdf(x,prior.mu,sqrt(prior.sigma))));

   %% EXPECTATION STEP
   for is = 1:n_subj

      ex = -1;

      while ex < 0
          q = .1*randn(fit.npar,1);
          inputfun = @(q) fit.objfunc(rootfile.beh{is}, q, fit, modelID, bounds, prior);
          [q,fval,ex,~,~,hessian] = fminunc(inputfun, q, fit.options);
      end

      m(:,is)   = q;

      % Ensure symmetric Hessian
      h(:,:,is) = (hessian + hessian')/2;

      NPL(is,iiter)     = fval;
      NLPrior(is,iiter) = -prior.logpdf(q);
   end

   %% MAXIMISATION STEP
   [curmu,cursigma,flagcov,~] = compGauss_ms(m,h);

   if flagcov == 1
       posterior.mu    = curmu;
       posterior.sigma = cursigma;
   end

   fprintf('.');

   if abs(sum(NPL(:,iiter)) - NPL_old) < fit.convCrit && flagcov == 1
      fprintf('...converged!!!!! \n');
      break
   end

   NPL_old = sum(NPL(:,iiter));
end

[~,~,~,covmat_out] = compGauss_ms(m,h,2);

if iiter == fit.maxit
    fprintf('...maximum number of iterations reached \n');
end

%% ======================= SAVE OUTPUT =======================
modout.(modelID) = struct();
modout.(modelID).date        = date;
modout.(modelID).behaviour   = rootfile.beh;
modout.(modelID).q           = m';
modout.(modelID).qnames      = {};
modout.(modelID).hess        = h;

modout.(modelID).gauss.mu    = posterior.mu;
modout.(modelID).gauss.sigma = posterior.sigma;
modout.(modelID).gauss.cov   = covmat_out;

try
    modout.(modelID).gauss.corr = corrcov(covmat_out);
end

modout.(modelID).fit.npl      = NPL(:,iiter);
modout.(modelID).fit.NLPrior  = NLPrior(:,iiter);
modout.(modelID).fit.nll      = NPL(:,iiter) - NLPrior(:,iiter);

[modout.(modelID).fit.aic, modout.(modelID).fit.bic] = ...
    aicbic(-modout.(modelID).fit.nll, fit.npar, fit.ntrials);

modout.(modelID).fit.bounds = bounds;
modout.(modelID).ntrials    = fit.ntrials;

%% ======================= LME (FIXED) =======================
L = nan(n_subj,1);
goodHessian = false(n_subj,1);

for is = 1:n_subj
    try
        H = h(:,:,is);

        % Symmetrise again for safety
        H = (H + H')/2;

        % Add ridge if needed
        lam = 1e-6;
        tries = 0;
        p = 1;

        while p ~= 0 && tries < 6
            [R,p] = chol(H + lam*eye(size(H)));
            if p ~= 0
                lam = lam * 10;
                tries = tries + 1;
            end
        end

        if p == 0
            logdetH = 2 * sum(log(diag(R)));
            L(is) = -NPL(is,iiter) - 0.5*logdetH + (fit.npar/2)*log(2*pi);
            goodHessian(is) = true;
        else
            L(is) = NaN;
        end

    catch
        L(is) = NaN;
    end
end

modout.(modelID).fit.lme = L;
modout.(modelID).fit.goodHessian = goodHessian;

%% ======================= SUBJECT OUTPUT =======================
fit.dofit   = 1;
fit.doprior = 0;

for is = 1:n_subj
   [~,subfit] = fit.objfunc(rootfile.beh{is}, m(:,is), fit, modelID, bounds, prior);
   modout.(modelID).qnames = subfit.xnames;
   modout.(modelID).sub{is}.mat        = subfit.mat;
   modout.(modelID).sub{is}.names      = subfit.names;
   modout.(modelID).sub{is}.choiceprob = subfit.choiceprob;
end

end