function M = vector_strength(trials,varargin)
% M = vector_strength(trials,par)
% M = vector_strength(trials,'Name',Value,...)
% 
% Compute trial-by-trial vector strength.
% 
% Trial Input:
%   trials  ... [Nx1] cell array with spike times normalized by an event
%               onset. Each cell contains spike times for a single 'trial'.
%               See epa.Cluster.triallocked
% 
% Parameter Inputs:
%   modfreq     ...     modulation frequency (Hz) (no default)
% 
% Outputs:
%   M           ...     [Nx1] array of the mean vector strength.
% 
% Adapted from: Yin et al, 2010, J. Neurophysiol 105: 582-600, 2011
% 
% DJS 2021

par.modfreq = [];

if isequal(trials,'getdefaults'), M = par; return; end

par = epa.helper.parse_params(par,varargin{:});


p = 1./par.modfreq; % modulation period

th = cellfun(@(t) 2.*pi.*(mod(t,p)./p),trials,'uni',0);

M = cellfun(@(th) sqrt(sum(cos(th).^2)+sum(sin(th).^2))./length(th),th);
