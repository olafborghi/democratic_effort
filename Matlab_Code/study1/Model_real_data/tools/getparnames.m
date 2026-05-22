function params = getparnames(modelID, rootfile)
%GETPARNAMES  Return parameter names for a given model string.
%   Adapts to the number of agents present in the data.
%
%   modelID  : string such as 'ms_three_k_three_beta_linear'
%   rootfile : struct containing .beh{1,1} with trial structs (used to detect agents)
%
%   Returns a cell array of parameter names.

% --- detect unique agent codes from the data ---
agents = unique([rootfile.beh{1,1}.agent]);
nAgents = numel(agents);

% Map numeric codes to descriptive labels
labelMap = containers.Map('KeyType','double','ValueType','char');
if any(agents==1), labelMap(1) = 'all';   end
if any(agents==2), labelMap(2) = 'rural'; end
if any(agents==3), labelMap(3) = 'urban'; end

params = {};

%% --- k parameters ---
if contains(modelID,'_k_one')
    % one shared k across all agents
    params{end+1} = 'k';
elseif contains(modelID,'_k_two')
    for a = agents
        if isKey(labelMap,a)
            params{end+1} = ['k_' labelMap(a)];
        else
            params{end+1} = sprintf('k_agent%d',a);
        end
    end
elseif contains(modelID,'_k_three')
    for a = agents
        if isKey(labelMap,a)
            params{end+1} = ['k_' labelMap(a)];
        else
            params{end+1} = sprintf('k_agent%d',a);
        end
    end
elseif ~contains(modelID,'k')
    % no k parameter in this model
else
    error(['Can''t determine number of k parameters from model name: ', modelID])
end

%% --- beta parameters ---
if contains(modelID,'one_beta')
    params{end+1} = 'beta';
elseif contains(modelID,'two_beta')
    for a = agents
        if isKey(labelMap,a)
            params{end+1} = ['beta_' labelMap(a)];
        else
            params{end+1} = sprintf('beta_agent%d',a);
        end
    end
elseif contains(modelID,'three_beta')
    for a = agents
        if isKey(labelMap,a)
            params{end+1} = ['beta_' labelMap(a)];
        else
            params{end+1} = sprintf('beta_agent%d',a);
        end
    end
else
    error(['Can''t determine number of beta parameters from model name: ', modelID])
end

end
