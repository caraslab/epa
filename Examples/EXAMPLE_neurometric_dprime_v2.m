%%


% set parameters for computing neurometric dprime
par = [];
par.event = "AMdepth";
par.referenceval = 0;
par.window = [0 1];
par.modfreq = 5;

% par.metric = @epa.metric.trial_firingrate;
% par.metric = @epa.metric.cl_calcpower;
% par.metric = @epa.metric.tmtf; % use the temporal Modualation Transfer Function metric
% par.metric = @epa.metric.vector_strength;
% par.metric = @epa.metric.vector_strength_phase_projected;
par.metric = @epa.metric.vector_strength_cycle_by_cycle;


C = S.common_Clusters;

R = nan(numel(C),2);
for i = 1:numel(C)
    
    for j = 1:numel(S)
        sC = S(j).find_Cluster(C(i).Name);
        [dp,v] = sC.neurometric_dprime(par);
        if ~isempty(dp)
            R(i,j) = dp(end);
        end
    end
    
end





