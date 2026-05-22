function [rootfile] = choiceProbR2(rootfile, modelID, EM)
% Compute descriptive "choice probability R²" metrics from predicted choice
% probabilities stored per trial. Uses mean or median across trials, then
% squares those aggregates. This is NOT a variance-explained metric.

% Detect EM vs ML if not provided
if nargin < 3
    EM = NaN;
    while isnan(EM)
        if isfield(rootfile, 'em') && ~isfield(rootfile, 'ml')
            EM = 1;
        elseif ~isfield(rootfile, 'em') && isfield(rootfile, 'ml')
            EM = 0;
        elseif isfield(rootfile, 'em') && isfield(rootfile, 'ml')
            if ~isempty(rootfile.em) && isempty(rootfile.ml)
                EM = 1;
            elseif isempty(rootfile.em) && ~isempty(rootfile.ml)
                EM = 0;
            end
        end
        if isnan(EM)
            error('Cannot find em or ml model details in the model structure');
        end
    end
end

fitops = {'ml','em'};
n_subj = numel(rootfile.beh);

if EM == 0
    % ML path (kept for compatibility)
    try
        for is = 1:n_subj
            % Expect ML path to have .info.prob as prob of observed choice
            prob_chosen = rootfile.(fitops{EM+1}).(modelID){is}.info.prob;
            prob_chosen = prob_chosen(:);
            prob_chosen = max(min(prob_chosen, 1), 0); % clip
            rootfile.(fitops{EM+1}).fit.(modelID).eachSubProbMean(is,1)    = nanmean(prob_chosen);
            rootfile.(fitops{EM+1}).fit.(modelID).eachSubProbMedian(is,1)  = nanmedian(prob_chosen);
        end
    catch
        warning('choiceProbR2: ML path missing .info.prob; metrics may be incomplete.');
    end

    rootfile.(fitops{EM+1}).fit.(modelID).allSubProbMedian    = nanmedian(rootfile.(fitops{EM+1}).fit.(modelID).eachSubProbMedian);
    rootfile.(fitops{EM+1}).fit.(modelID).allSubProbMean      = nanmean( rootfile.(fitops{EM+1}).fit.(modelID).eachSubProbMean);
    rootfile.(fitops{EM+1}).fit.(modelID).eachSubProbMedianR2 = (rootfile.(fitops{EM+1}).fit.(modelID).eachSubProbMedian).^2;
    rootfile.(fitops{EM+1}).fit.(modelID).eachSubProbMeanR2   = (rootfile.(fitops{EM+1}).fit.(modelID).eachSubProbMean).^2;
    rootfile.(fitops{EM+1}).fit.(modelID).choiceProbMedianR2  = (rootfile.(fitops{EM+1}).fit.(modelID).allSubProbMedian)^2;
    rootfile.(fitops{EM+1}).fit.(modelID).choiceProbMeanR2    = (rootfile.(fitops{EM+1}).fit.(modelID).allSubProbMean)^2;

elseif EM == 1
    % EM path. We expect per-trial chosen probabilities at:
    % rootfile.em.(modelID).sub{1,is}.choiceprob
    try
        for is = 1:n_subj
            prob_chosen = rootfile.(fitops{EM+1}).(modelID).sub{1,is}.choiceprob;
            prob_chosen = prob_chosen(:);
            prob_chosen = max(min(prob_chosen, 1), 0); % clip
            rootfile.(fitops{EM+1}).(modelID).fit.eachSubProbMean(is,1)   = nanmean(prob_chosen);
            rootfile.(fitops{EM+1}).(modelID).fit.eachSubProbMedian(is,1) = nanmedian(prob_chosen);
        end
    catch
        warning('choiceProbR2: EM path missing .sub{is}.choiceprob; metrics may be incomplete.');
    end

    rootfile.(fitops{EM+1}).(modelID).fit.allSubProbMedian     = nanmedian(rootfile.(fitops{EM+1}).(modelID).fit.eachSubProbMedian);
    rootfile.(fitops{EM+1}).(modelID).fit.allSubProbMean       = nanmean(  rootfile.(fitops{EM+1}).(modelID).fit.eachSubProbMean);
    rootfile.(fitops{EM+1}).(modelID).fit.eachSubProbMedianR2  = (rootfile.(fitops{EM+1}).(modelID).fit.eachSubProbMedian).^2;
    rootfile.(fitops{EM+1}).(modelID).fit.eachSubProbMeanR2    = (rootfile.(fitops{EM+1}).(modelID).fit.eachSubProbMean).^2;
    rootfile.(fitops{EM+1}).(modelID).fit.choiceProbMedianR2   = (rootfile.(fitops{EM+1}).(modelID).fit.allSubProbMedian)^2;
    rootfile.(fitops{EM+1}).(modelID).fit.choiceProbMeanR2     = (rootfile.(fitops{EM+1}).(modelID).fit.allSubProbMean)^2;
end
end
