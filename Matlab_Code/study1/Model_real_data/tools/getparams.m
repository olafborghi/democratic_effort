function out = getparams(rootfile, modelID, bounds, IDs)
% Returns per-subject parameters in native space with correct column names.
% Works for 1/2/3 k and 1/2/3 beta models.

% Locate fitted model
M = rootfile.em.(modelID);

% Parameter names from the up-to-date mapper
pnames = get_params(modelID);              % e.g., {'k_agent1','k_agent2','k_agent3','beta'}

% Gaussian-space params: subjects × params (your EMfit_ms_par saves m' here)
if isfield(M,'q'), q_norm = M.q; else, error('Missing field: M.q'); end

% Bounds: prefer fitted bounds stored with the model; fallback to provided
if isfield(M,'fit') && isfield(M.fit,'bounds')
    b = M.fit.bounds;
else
    b = bounds;
end
if ~isfield(b,'lower') || ~isfield(b,'upper')
    error('Bounds must provide .lower and .upper vectors.');
end

% Sanity checks
n_subj = size(q_norm,1);
n_par  = size(q_norm,2);
if n_par ~= numel(pnames)
    error('Parameter count mismatch: q has %d cols, names has %d.', n_par, numel(pnames));
end
if numel(b.lower) ~= n_par || numel(b.upper) ~= n_par
    error('Bounds length mismatch: lower/upper must match %d parameters.', n_par);
end
if nargin >= 4 && numel(IDs) ~= n_subj
    warning('IDs count (%d) != subjects (%d). Using row indices as IDs.', numel(IDs), n_subj);
    IDs = arrayfun(@(i) sprintf('S%03d',i), 1:n_subj, 'uni', 0);
elseif nargin < 4
    IDs = arrayfun(@(i) sprintf('S%03d',i), 1:n_subj, 'uni', 0);
end

% Transform each parameter column to native space
q_nat = nan(size(q_norm));
for p = 1:n_par
    q_nat(:,p) = norm2positive(q_norm(:,p), [b.lower(p), b.upper(p)]);
end

% Build table with correct column names
all_table = array2table(q_nat, 'VariableNames', pnames);
all_table.ID = string(IDs(:));
all_table = movevars(all_table, 'ID', 'Before', 1);

% Package outputs
out = struct();
out.all_table = all_table;
out.names     = pnames;
out.q_nat     = q_nat;
out.bounds    = b;

end
