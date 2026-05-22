% edited by Mariana von Mohr 2025 
% CHANGE: In this dataset choices are only 0/1 (accept/reject), unlike the original 
% task which used "2" for missing trials, so we count all rows instead.

function [modout]= EMfit_ms_par(rootfile, modelID, bounds)
% 2017; does Expectation-maximisation fitting. Originally written by Elsa
% Fouragnan, modified by MKW and Patricia Lockwood 1st July 2019
%
% INPUT:       - rootfile: file with all behavioural information necessary for fitting + outputroot
%              - modelID: ID of model to fit
% OUTPUT:      - fitted model
%
% DEPENDENCIES: - norm2par
%               - get_npar
%               - EMmc_ms
%
% CHANGE (Mariana von Mohr, 2025):
% The original code assumed that choices could take the value "2" to denote
% missing/invalid trials:
%       fit.ntrials(is) = sum((rootfile.beh{is}.choice ~= 2));
% In the Democratic Effort Task, choices are only coded {0 = reject, 1 = accept}.
% Therefore, this has been replaced with:
%       fit.ntrials(is) = numel(rootfile.beh{is});
% which simply counts all rows in the participant's trial data.

qfit = 0;
%======================================================================================================
% 1) do settings and prepare model
%======================================================================================================

fprintf([rootfile.expname ': Fitting ' modelID ' using EM.']);

% assign input variables
modout      = rootfile.em;
n_subj      = length(rootfile.beh);
bounds      = get_bounds(rootfile, modelID, bounds);

% number of trials per subject
fit.ntrials = nan(length(rootfile.beh),1);
for is = 1:n_subj
    fit.ntrials(is) = numel(rootfile.beh{is});
end

% define model and fitting params:
if qfit==1
    fit.convCrit= .5; 
else
    fit.convCrit= 1e-3; 
end
fit.maxit   = 800; 
fit.npar    = get_npar(modelID);   
fit.objfunc = str2func('mod_ms_all'); 
fit.doprior = 1;
fit.dofit   = 0;  
fit.options = optimoptions(@fminunc,'Display','off','TolX',.0001,'Algorithm','quasi-newton'); 
if isfield(fit,'maxEvals')
    fit.options = optimoptions(@fminunc,'Display','off','TolX',.0001,'MaxFunEvals', fit.maxEvals,'Algorithm','quasi-newton'); 
end

% initialise group-level parameter mean and variance
posterior.mu        = abs(.1.*randn(fit.npar,1)); 
posterior.sigma     = repmat(100,fit.npar,1);

% initialise transient variables:
nextbreak   = 0;
NPL         = [];                                                     
NPL_old     = -Inf;
NLL         = [] ;                                                    
NLPrior     = [];                                                     

%======================================================================================================
% 2) EM FITTING
%======================================================================================================
for iiter = 1:fit.maxit                         
   
   m=[];  
   h=[];  
   
   % build prior gaussian pdfs
   prior.mu       = posterior.mu;
   prior.sigma    = posterior.sigma;
   prior.logpdf  = @(x) sum(log(normpdf(x,prior.mu,sqrt(prior.sigma))));      

   %======================= EXPECTATION STEP ==============================
   for is = 1:n_subj                                                          
      ex=-1; tmp=0; 
      while ex<0   
          q        =.1*randn(fit.npar,1);            
          inputfun = @(q)fit.objfunc(rootfile.beh{is}, q, fit, modelID, bounds, prior);
          [q,fval,ex,~,~,hessian] = fminunc(inputfun, q, fit.options); 
          if ex<0 
              tmp=tmp+1; 
              fprintf('didn''t converge %i times exit status %i\r',tmp,ex); 
          end
      end

      m(:,is)              = q;
      h(:,:,is)            = hessian;  
      
      % get MAP model fit:
      NPL(is,iiter)     = fval; 
      NLPrior(is,iiter) = -prior.logpdf(q);    
   end

   %======================= MAXIMISATION STEP ==============================
   [curmu,cursigma,flagcov,~] = compGauss_ms(m,h);                            
   if flagcov==1, posterior.mu = curmu; posterior.sigma = cursigma; end       
   fprintf(['.']);
   if abs(sum(NPL(:,iiter))-NPL_old) < fit.convCrit  && flagcov==1            
      fprintf('...converged!!!!! \n');  nextbreak=1;                                                        
   end
   NPL_old = sum(NPL(:,iiter));
   
   if nextbreak ==1 
      break 
   end
end
[~,~,~,covmat_out] = compGauss_ms(m,h,2);

if iiter == fit.maxit 
    fprintf('...maximum number of iterations reached \n');
end

%======================================================================================================
%%% 3) Get values for best fitting model
%====================================================================================================== 

modout.(modelID) = {}; 
modout.(modelID).date            = date;
modout.(modelID).behaviour       = rootfile.beh;                                          
modout.(modelID).q               = m';
modout.(modelID).qnames          = {};                                                    
modout.(modelID).hess            = h;
modout.(modelID).gauss.mu        = posterior.mu;
modout.(modelID).gauss.sigma     = posterior.sigma;
modout.(modelID).gauss.cov       = covmat_out;
try
    modout.(modelID).gauss.corr  = corrcov(covmat_out);
catch
end
modout.(modelID).fit.npl         = NPL(:,iiter);                                          
modout.(modelID).fit.NLPrior     = NLPrior(:,iiter);
modout.(modelID).fit.nll         = NPL(:,iiter) - NLPrior(:,iiter); 
[modout.(modelID).fit.aic,modout.(modelID).fit.bic] = aicbic(-modout.(modelID).fit.nll,fit.npar,fit.ntrials); 
modout.(modelID).fit.convCrit    = fit.convCrit;
modout.(modelID).fit.maxit       = fit.maxit;
modout.(modelID).fit.iiter       = iiter;
modout.(modelID).fit.bounds      = bounds;
modout.(modelID).ntrials         = fit.ntrials;

% -------------------------------------------------------------------------
% Compute log model evidence (Laplace approximation)
% -------------------------------------------------------------------------
L = nan(n_subj,1);
goodHessian = nan(n_subj,1);

for is = 1:n_subj
    try
        L(is) = -NPL(is,iiter) - 0.5*log(det(h(:,:,is))) + (fit.npar/2)*log(2*pi);
        if ~isreal(L(is))
            L(is) = nan;
            goodHessian(is) = 0;
            warning(['L complex for sub ', num2str(is)]);
        else
            goodHessian(is) = 1;
        end
    catch
        warning(['Hessian not positive definite for sub ', num2str(is)]);
        L(is) = nan;
        goodHessian(is) = 0;
    end
end
% replace NaNs with group mean if needed
L(isnan(L)) = nanmean(L);

modout.(modelID).fit.lme = L;
modout.(modelID).fit.goodHessian = goodHessian;

% -------------------------------------------------------------------------
% Get subject specifics
% -------------------------------------------------------------------------
fit.dofit   = 1;
fit.doprior = 0;

for is = 1:n_subj
   [nll_check,subfit] = fit.objfunc(rootfile.beh{is}, m(:,is), fit, modelID, bounds, prior); 
   modout.(modelID).qnames           = subfit.xnames;  
   modout.(modelID).sub{is}.mat      = subfit.mat;
   modout.(modelID).sub{is}.names    = subfit.names;
   modout.(modelID).sub{is}.choiceprob= subfit.choiceprob;
end

%======================================================================================================
%%% 4)  plot correlation between parameters
%====================================================================================================== 
try
    subplot(2,1,2);
    imagesc(modout.(modelID).gauss.corr)
    colorbar
    colormap jet
    caxis([-1 1])
    title('Parameter Correlation Matrix');
    set(gca,'Xtick',1:fit.npar,'XTickLabel',modout.(modelID).qnames)
    set(gca,'Ytick',1:fit.npar,'YTickLabel',modout.(modelID).qnames)
catch
end

end
