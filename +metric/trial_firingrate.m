function M = trial_firingrate(trials,par)
% M = trial_firingrate(trials,par)

dw = diff(par.window);
M = cellfun(@(a) numel(a)./dw,trials);
