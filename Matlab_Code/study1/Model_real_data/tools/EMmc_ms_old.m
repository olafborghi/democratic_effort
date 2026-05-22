function [rootfile] = EMmc_ms(rootfile,modnames)
% Model comparison for EM fitted models
% Originally: MK Wittmann, Nov 2017
% Adapted (MvM 2025): Democratic Effort Task

expname = rootfile.expname;

% Preallocate
nmods  = numel(modnames);
nsubj  = numel(rootfile.ID);
lme    = nan(nsubj,nmods);
bicint = nan(1,nmods);

% Collect evidence for each model
for imod = 1:nmods
    if isfield(rootfile.em.(modnames{imod}).fit,'lme')
        lme(:,imod) = rootfile.em.(modnames{imod}).fit.lme;
    else
        warning('EMmc_ms:NoLME','No lme found for %s',modnames{imod});
    end
    if isfield(rootfile.em.(modnames{imod}).fit,'bicint')
        bicint(imod) = rootfile.em.(modnames{imod}).fit.bicint;
    else
        warning('EMmc_ms:NoBICint','No bicint found for %s',modnames{imod});
    end
end

%% Plot LME and BIC
h = figure('name', expname);

subplot(2,2,1);
bar(sum(lme,1,'omitnan'));
set(gca,'XTick',1:nmods,'XTickLabel',modnames,'XTickLabelRotation',25);
ylabel('Summed log evidence (higher = better)','FontWeight','bold');

subplot(2,2,2);
bar(bicint);
set(gca,'XTick',1:nmods,'XTickLabel',modnames,'XTickLabelRotation',25);
ylabel('BICint (lower = better)','FontWeight','bold');

%% Pairwise comparison of best two models
try
    % take two best by lowest BICint
    [~, order] = sort(bicint, 'ascend');
    bestIdx   = order(1);
    secondIdx = order(2);
    compM = {modnames{bestIdx}, modnames{secondIdx}};
    
    subplot(2,2,3);
    lmepair = [rootfile.em.(compM{1}).fit.lme, ...
               rootfile.em.(compM{2}).fit.lme];
    lmediff = lmepair(:,2) - lmepair(:,1);
    barh(1:numel(lmediff), sort(lmediff));
    set(gca,'ytick',1:numel(lmediff));
    ylabel('Subjects (sorted)');
    xlabel([compM{1} ' vs. ' compM{2}]);
    title('Log Evidence Differences / Bayes factor');
catch ME
    warning('EMmc_ms:PairwiseComparisonFailed','%s', ME.message);
end

%% Exceedance probabilities via spm_BMS
try
    [~,~,BMS.xp] = spm_BMS(lme);
    subplot(2,2,4);
    bar(BMS.xp);
    set(gca,'XTick',1:nmods,'XTickLabel',modnames,'XTickLabelRotation',25);
    rl1 = refline(0,.95); set(rl1,'linestyle','--','Color','r');
    ylabel('Exceedance Probability','FontWeight','bold');
    
    % Save into rootfile
    for imod = 1:nmods
        rootfile.em.(modnames{imod}).fit.xp = BMS.xp(imod);
    end
catch ME
    warning('EMmc_ms:SPMBMSFailed','%s', ME.message);
end

setfp(gcf);
figname = ['figs/EM_BMC_' expname '_' date];
% saveas(gcf,figname);

end
