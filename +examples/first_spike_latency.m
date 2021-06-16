%% Example first_spike_latency

D = DataViewer;

%% Select one AM Cluster from the DataViewer and then run this section

C = D.curClusters;



% set parameters for computing the metric
par = [];
par.event = D.curEvent1;
par.eventvalue = D.curEvent1Values;
par.window = [-.2 0.4];


% normalize spike times to the nearest event onset
[trials,values,eidx] = C.triallocked(par);

% copy the values for each trial to the 'par' structure used by the metric
par.values = values;



par.minlag = 0.05;
par.maxlag = 0.25;
par.windur = 0.005;
par.p_value = 0.95;

firstSpikeLatency = epa.metric.first_spike_latency(trials,par);

figure(999);
clf

subplot(211)
p = epa.plot.Raster(C,par);
p.markerstyle = 'point';
p.markersize = 10;
p.plot;

hold(p.ax,'on');
plot(p.ax,firstSpikeLatency,eidx,'or','markersize',5);


subplot(212)
x = par.minlag:par.windur:par.maxlag;
uv = unique(values);
cla
hold on
for i = 1:length(uv)
    ind = uv(i) == values;
    histogram(firstSpikeLatency(ind),x,'Normalization','probability');
end
hold off
xlim(par.window);
xlabel('time to first spike');
ylabel('probability');
grid on

h = legend(num2str(uv));
h.Title.String = par.event.Name;
