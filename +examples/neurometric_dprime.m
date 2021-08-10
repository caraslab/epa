%% Example: Compute neurometric dprime and fit a sigmoidal function.
%  Add the result as a new property to each Cluster object

% first select only the relevant Session objects

X = D.curClusters;
S_AM = [S.find_Session("Pre") S.find_Session("AM") S.find_Session("Post")];

for i = 1:length(X)
    C(i,:) = S_AM.find_Cluster(X(i).Name);
end

% process all Clusters independently.
% the following statement simplifies accessing all of the clusters from all
% "S_AM" Session objects.  you can always access the original Session
% object data for each Cluster by using C(1).Session. remember that you are
% only copying the object handles and not the actual data, so changing data
% in "C" will will change the original data as well.  you could make an
% independent copy of the data (instead of just copying the object handle)
% by using the "copy" function. ex: C_copied = copy(C);
% C = [S_AM.Clusters];

%% 



% add a new property, called "neurodprime" only if it doesn't already exist
% note: you don't need to add a property in this way.  You could just make
% a new variable in the workspace of course, but it's often convenient to
% keep the data together.
ind = ~isprop(C,'neurodprime');
addprop(C(ind),'neurodprime');

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

% compute neurometric dprime for each Cluster independently
dprimeThreshold = 1;

%% 

figure
% clf(999)
tiledlayout('flow');

% for i = [4, 12, 20]
% C = D.curClusters;
for i = 1:numel(C)
    
    if C(i).N < 100
        fprintf(2,'Cluster #%d (%s) had only %d spikes, skipping\n',i,C(i).Name,C(i).N)
        continue
    end

    % compute neurometric_dprime
    [dp,v] = C(i).neurometric_dprime(par);
    
    
    
    
    % fit the data with a sigmoidal function
    [xfit,yfit,p_val] = epa.analysis.fit_sigmoid(v,dp);
    
    
    
    
    % determine where on the x-axis intersects with the neurometric curve
    % at dprimeThreshold
    if max(yfit) >= dprimeThreshold && min(yfit) <= dprimeThreshold
        try
            value_at_threshold = spline(yfit,xfit,dprimeThreshold);
        catch
            % spline doesn't like some extreme fits, so fall back on
            % finding the nearest point
            [~,m] = min((yfit - dprimeThreshold).^2);
            value_at_threshold = xfit(m);
        end
    else
        value_at_threshold = nan;
    end
    
    
    % store the results along with the Cluster object
    C(i).neurodprime.dprime = dp;
    C(i).neurodprime.vals   = v;
    C(i).neurodprime.xfit   = xfit;
    C(i).neurodprime.yfit   = yfit;
    C(i).neurodprime.p_val  = p_val;
    C(i).neurodprime.threshold = value_at_threshold;
    
    
    
    
    % plot the results
    nexttile
    
    h = plot(v,dp,'--o', ...
        xfit,yfit,'-k', ...
        value_at_threshold,dprimeThreshold,'+r');
    
    h(3).MarkerSize = 10;
    h(3).LineWidth = 2;
    
    xlabel(par.event)
    ylabel('d''')
    
    title({C(i).Session.Name; ...
           C(i).TitleStr; ...
           sprintf('\\it{threshold = %.2f; p = %.4f}',value_at_threshold,p_val)});
    
    grid on
end

%%

% Since the array C is only of handles to the orignal Cluster objects,
% the original Cluster objects are already updated.
S_AM(1).Clusters(1).neurodprime




%%

parentDir = '/mnt/CL_4TB_2/Rose/IC recording/SUBJ-ID-202/Sessions';
mkdir(parentDir,'Sorted')

fullFileName = fullfile(parentDir,'Sorted','210611.mat');

fprintf('Saving %s ...',fullFileName)

save(fullFileName,'C');

fprintf(' done\n')





