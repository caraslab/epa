function M = vector_strength(trials,par)
% M = vector_strength(trials,par)
% 
% Yin et al, 2010, J. Neurophysiol 105: 582-600, 2011

p = 1./par.modfreq; % modulation period

th = cellfun(@(t) 2.*pi.*(mod(t,p)./p),trials,'uni',0);

M = cellfun(@(th) sqrt(sum(cos(th).^2)+sum(sin(th).^2))./length(th),th);
