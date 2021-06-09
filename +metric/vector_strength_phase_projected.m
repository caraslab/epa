function M = vector_strength_phase_projected(trials,par)
% M = vector_strength_phase_projected(trials,par)
% 
% Yin et al, 2010, J. Neurophysiol 105: 582-600, 2011

mp = 1./par.modfreq; % modulation period

% compute phase of each spike relative tothe modulation period
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
