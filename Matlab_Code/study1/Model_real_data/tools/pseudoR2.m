function r2 = pseudoR2(rootfile, modelID, nopt, EM)
% McFadden-style pseudo R^2 against a chance model.
% Computes per-subject then aggregates robustly.
% Returns a scalar r2 in [0,1].

% ---- defaults ----
if nargin < 3 || isempty(nopt), nopt = 2; end

% ---- detect EM vs ML if not provided ----
if nargin < 4
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
            error('pseudoR2: Cannot find em or ml model details in the model structure');
        end
    end
end
fitops = {'ml','em'};

% ---- subjects and trial counts ----
if ~isfield(rootfile,'beh') || isempty(rootfile.beh)
    error('pseudoR2: rootfile.beh is missing or empty');
end
n_subj = numel(rootfile.beh);
nr_trials = zeros(n_subj,1);
for is = 1:n_subj
    c = [rootfile.beh{is}.choice];
    nr_trials(is) = numel(c); % all trials valid in DET
end

% ---- model NLL per subject ----
nllModel = NaN(n_subj,1);

% preferred: use stored NLL if available
try
    stored = rootfile.(fitops{EM+1}).(modelID).fit.nll;
    if numel(stored) == n_subj
        nllModel = stored(:);
    end
catch
    % fallback below
end

% fallback: derive from per-trial chosen probabilities
need_idx = isnan(nllModel);
if any(need_idx)
    if EM == 1
        try
            for is = find(need_idx').'
                prob_chosen = rootfile.(fitops{EM+1}).(modelID).sub{1,is}.choiceprob;
                prob_chosen = prob_chosen(:);
                prob_chosen = max(min(prob_chosen, 1-1e-12), 1e-12);
                nllModel(is) = -nansum(log(prob_chosen));
            end
        catch
            error('pseudoR2: Could not find EM per-trial choice probabilities.');
        end
    else
        try
            for is = find(need_idx').'
                prob_chosen = rootfile.(fitops{EM+1}).(modelID){is}.info.prob;
                prob_chosen = prob_chosen(:);
                prob_chosen = max(min(prob_chosen, 1-1e-12), 1e-12);
                nllModel(is) = -nansum(log(prob_chosen));
            end
        catch
            error('pseudoR2: Could not find ML per-trial choice probabilities.');
        end
    end
end

% guard: any remaining NaNs mean failure
if any(isnan(nllModel))
    error('pseudoR2: nllModel contains NaNs after all attempts');
end

% ---- null model NLL per subject ----
nllChance = NaN(n_subj,1);
for is = 1:n_subj
    ntr = nr_trials(is);
    [nllChance(is),~,~] = mk_0mod(ntr, nopt);
end

% guard against zero or negative chance NLL
badChance = nllChance <= 0 | isnan(nllChance);
if any(badChance)
    warning('pseudoR2: invalid chance NLL detected, setting affected subjects to NaN');
    nllChance(badChance) = NaN;
end

% ---- pseudo-R^2 per subject then robust aggregate ----
r2_subj = 1 - (nllModel ./ nllChance);
r2_subj = max(0, min(1, r2_subj)); % cap to [0,1]
r2 = median(r2_subj, 'omitnan');

% optional: if all NaN after guards, return 0
if isnan(r2), r2 = 0; end
end
