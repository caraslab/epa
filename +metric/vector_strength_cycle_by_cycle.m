function M = vector_strength_cycle_by_cycle(trials,par)
% M = vector_strength_cycle_by_cycle(trials,par)
% 
% Yin et al, 2010, J. Neurophysiol 105: 582-600, 2011

mp = 1/par.modfreq; % modulation period

cvec = par.window(1):mp:par.window(2);

VScc = nan(length(trials),length(cvec));
k = 1;
for c = cvec
    % current modulation period spikes
    ctrials = cellfun(@(t) t(t>=c(1)&t<c(1)+mp),trials,'uni',0);
    
    
    % compute phase of each spike relative to the modulation period
    th = cellfun(@(t) 2.*pi.*(mod(t,mp)./mp),ctrials,'uni',0);
    
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
    x = VS .* cos(phi_t - phi_c);
    x(isnan(x)) = 0;
    VScc(:,k) = x;
    k = k + 1;
end


M = mean(VScc,2,'omitnan');