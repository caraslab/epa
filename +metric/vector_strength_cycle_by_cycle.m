function [M,VScc] = vector_strength_cycle_by_cycle(trials,par)
% M = vector_strength_cycle_by_cycle(trials,par)
% [M,VScc] = vector_strength_cycle_by_cycle(trials,par)
% 
% Required par fields:
%   modfreq     ...     modulation frequency (Hz)
%   values      ...     values corresponding to each cell in trials
%   window      ...     [1x2] analysis window [onset offset], in seconds
%                       relative to the trial onset.
% 
% DJS 2021
% 
% See: Yin et al, 2010, J. Neurophysiol 105: 582-600, 2011

mp = 1/par.modfreq; % modulation period

cvec = par.window(1):mp:par.window(2);
cvec(cvec==par.window(2)) = [];

uvals = unique(par.values);

% function to compute phase angle phi
phi = @(th) atan2(sum(sin(th)),sum(cos(th)));

VScc = nan(length(trials),length(cvec));
k = 1;

% for each modulation period...
for c = cvec
    % current modulation period spikes
    ctrials = cellfun(@(t) t(t>=c(1)&t<c(1)+mp),trials,'uni',0);
    
    
    % compute phase of each spike relative to the modulation period for each trial
    th = cellfun(@(t) 2.*pi.*(mod(t,mp)./mp),ctrials,'uni',0);
    
    
    % compute the trial-by-trial phase angle phi
    phi_t = cellfun(phi,th);
    
    
    
    % compute mean phase angle for each stimulus value
    phi_c = nan(size(phi_t));
    for i = 1:length(uvals)
        % compute across all trials of the same stimulus
        ind = par.values == uvals(i);
        th_subset = cell2mat(th(ind));
        phi_c(ind) = phi(th_subset);
    end
    
    nullInd = isempty(phi_t) | isempty(phi_c);
    
    % compute normal vector strength
    VS = cellfun(@(th) sqrt(sum(cos(th).^2)+sum(sin(th).^2))./length(th),th);
    
    % compute vector strength with phase projection
    x = VS .* cos(phi_t - phi_c);
    
    x(nullInd) = nan;
    
    VScc(:,k) = x;
    k = k + 1;
end


M = mean(VScc,2,'omitnan');


