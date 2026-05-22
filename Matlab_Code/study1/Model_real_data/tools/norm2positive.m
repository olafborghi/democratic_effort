function [ param_out ] = norm2positive(param, bound)
% Transformation from Gaussian space to a bounded positive space.
%
% INPUT:
%   param - normally distributed parameter(s)
%   bound - either a scalar [max] or a 2-element vector [min, max]
%
% OUTPUT:
%   param_out - transformed parameter(s), constrained to [0, max] or [min, max]
%
% NOTE (MvM 2025): Used to map free parameters (k, beta, etc.) from the 
% unconstrained fitting space into meaningful bounded values for interpretation. 
% This works for any number of agents without modification.

% if no upper value specified use 10
if nargin == 1
    bound = 10;
end

if length(bound) == 1
    % transform into [0, bound]
    param_out = (1 ./ (1 + exp(-param))) * bound;
elseif length(bound) == 2
    % transform into [bound(1), bound(2)]
    param_out = ((1 ./ (1 + exp(-param))) * (bound(2) - bound(1))) + bound(1);
end

end
