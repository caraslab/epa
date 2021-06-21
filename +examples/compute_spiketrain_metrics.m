%% Compute spike train metrics directly


DataPath = 'G:\My Drive\Caras Lab\ExampleData\SUBJ-ID-174\201116_concat';
S = epa.kilosort2session(DataPath);



% set parameters for computing the metric
par = [];
par.event = "AMdepth";
par.referenceval = 0;
par.window = [0 1];
par.modfreq = 5;


% only process Clusters that can be found across Sessions
C = S.common_Clusters;

clear VScc_*

% dims: Session x Cluster x Value(s)
VScc_mean = nan(numel(S),numel(C),1);
VScc_std = VScc_mean;
VScc_vals = VScc_mean;
for i = 1:numel(C)
    
    for j = 1:numel(S)
        thisCluster = S(j).find_Cluster(C(i).Name);
        
        % normalize spike times to the nearest event onset
        [trials,values] = thisCluster.triallocked(par);
        
        % copy the values for each trial to the 'par' structure used by the metric
        par.values = values;
        
        % compute the cycle-by-cycle vector strength for each trial
        M = epa.metric.vector_strength_cycle_by_cycle(trials,par);
        
        
        sessionName = thisCluster.Session.Name;
        sessionName = matlab.lang.makeValidName(sessionName);
        
        uvalues = unique(values);
        
        for k = 1:length(uvalues)
            ind = uvalues(k) == values;
            
            VScc_mean(j,i,k) = mean(M(ind));
            VScc_std(j,i,k)  = std(M(ind));
            
            VScc_vals(j,i,k) = uvalues(k);
            
        end
        
        
    end
    
end

%%

cla

% dims: Session x Cluster x Value(s)
x = VScc_mean(:,:,1);
y = VScc_mean(:,:,2);

h = plot(x,y,'-k', ...
    x(1,:),y(1,:),'o', ...
    x(2,:),y(2,:),'x');

r = [min([x(:); y(:)]), max([x(:); y(:)])];
xlim(r);
ylim(r);

axis square

hold on
plot(r,r,'-k');
hold off

grid on
xlabel('AMdepth = 0','interpreter','none');
ylabel('AMdepth = 1','interpreter','none');

title('VScc');










