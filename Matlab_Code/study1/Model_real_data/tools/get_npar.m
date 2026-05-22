function [npar] = get_npar(modelID)
% Lookup table to get number of free parameters per model
% Supports up to three k's and three betas
% JC 2022 (from MKW 2018), adapted by MvM 2025

%% k parameters
if contains(modelID,'three_k')
    nk = 3;
elseif contains(modelID,'two_k')
    nk = 2;
elseif contains(modelID,'one_k')
    nk = 1;
else
    nk = 0;
end

%% beta parameters
if contains(modelID,'three_beta')
    nb = 3;
elseif contains(modelID,'two_beta')
    nb = 2;
elseif contains(modelID,'one_beta')
    nb = 1;
else
    nb = 0;
end

%% total
npar = nk + nb;

end
