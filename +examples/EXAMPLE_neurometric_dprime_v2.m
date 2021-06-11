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


S = S201116;
% S = S201117;



C = S.common_Clusters;


R = nan(numel(C),2);
for i = 1:numel(C)
    
    for j = 1:numel(S)
        sC = S(j).find_Cluster(C(i).Name);
        
        [dp,v,M,V] = sC.neurometric_dprime(par);
        
        if ~isempty(dp)
            R(i,j) = dp;
        end
    end
    
end


%%
subplot(221)
plot([0 1],R20116','-ok');
hold on
plot([0 1],mean(R20116,'omitnan'),'-+r','markersize',10);
hold off
grid on
ylabel('d''');
title('R20116');
xlim([-.1 1.1])
set(gca,'XTick',[0 1],'XTickLabel',{'Passive-Pre','Aversive-AM'});

subplot(222)
plot([0 1],R20117','-ok');
hold on
plot([0 1],mean(R20117,'omitnan'),'-+r','markersize',10);
hold off
grid on
ylabel('d''');
title('R20117');
xlim([-.1 1.1])
set(gca,'XTick',[0 1],'XTickLabel',{'Passive-Pre','Aversive-AM'});


subplot(223)
plot(R20116(:,1),R20116(:,2),'ok');
grid on
xlabel('d'' Passive-Pre');
ylabel('d'' Aversive-AM');
axis square
s = [min([xlim ylim]) max([xlim ylim])];
xlim(s)
ylim(s)
hold on
plot(s,s,'-k');
hold off


subplot(224)
plot(R20117(:,1),R20117(:,2),'ok');
grid on
xlabel('d'' Passive-Pre');
ylabel('d'' Aversive-AM');
axis square
s = [min([xlim ylim]) max([xlim ylim])];
xlim(s)
ylim(s)
hold on
plot(s,s,'-k');
hold off
