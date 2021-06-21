function [M,VS,phi_t,phi_c] = vector_strength_phase_projected(trials,varargin)
% M = vector_strength_phase_projected(trials,par)
% M = vector_strength_phase_projected(trials,'Name',Value, ...)
% [M,VS,phi_t,phi_c] = vector_strength_phase_projected(trials,...)
% 
% Compute phase projected vector strength.
% 
% Trial Input:
%   trials  ... [Nx1] cell array with spike times normalized by an event
%               onset. Each cell contains spike times for a single 'trial'.
%               See epa.Cluster.triallocked
% 
% Parameter Inputs:
%   modfreq     ...     modulation frequency (Hz) (no default)
%   values      ...     values corresponding to each cell in trials (no
%                       default)
% 
% Outputs:
%   M           ...     [Nx1] array of the mean phase projected vector
%                       strength.
%   VS          ...     [NxP] matrix of the vector strength for each period
%                       of the signal.
%   phi_t       ...     [Nx1] array of the interim computation of the phase
%                       angle for each spike relative to the nearest
%                       preceding modulation period.
%   phi_c       ...     [Nx1] array of the interim computation of the mean
%                       overall phase angle.
% 
% Adapted from: Yin et al, 2010, J. Neurophysiol 105: 582-600, 2011
% 
% DJS 2021

par.modfreq = [];
par.values  = [];

if isequal(trials,'getdefaults'), M = par; return; end

par = epa.helper.parse_params(par,varargin{:});

mp = 1./par.modfreq; % modulation period

% compute phase of each spike relative to the modulation period
th = cellfun(@(t) 2.*pi.*(mod(t,mp)./mp),trials,'uni',0);

phi = @(th) atan2(sum(sin(th)),sum(cos(th)));

phi_t = cellfun(phi,th);

% compute mean phase angle for each stimulus value
uv = unique(par.values);
phi_c = nan(size(phi_t));
for i = 1:length(uv)
    ind = par.values == uv(i);
    p = cellfun(phi,th(ind));
    phi_c(ind) = mean(p);
end

% compute normal vector strength
VS = cellfun(@(th) sqrt(sum(cos(th).^2)+sum(sin(th).^2))./length(th),th);

% compute vector strength with phase projection
M = VS .* cos(phi_t - phi_c);
