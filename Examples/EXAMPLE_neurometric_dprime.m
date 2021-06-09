%% Example: Compute neurometric dprime and fit a sigmoidal function.
%  Add the result as a new property to each Cluster object

% first select only the relevant Session objects
S_AM = [S.find_Session("Pre") S.find_Session("AM") S.find_Session("Post")];




% process all Clusters independently.
% the following statement simplifies accessing all of the clusters from all
% "S_AM" Session objects.  you can always access the original Session
% object data for each Cluster by using C(1).Session. remember that you are
% only copying the object handles and not the actual data, so changing data
% in "C" will will change the original data as well.  you could make an
% independent copy of the data (instead of just copying the object handle)
% by using the "copy" function. ex: C_copied = copy(C);
C = [S_AM.Clusters];




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
% par.metric = 'cl_calcpower';
par.metric = 'tmtf'; % use the temporal Modualation Transfer Function metric

% compute neurometric dprime for each Cluster independently


figure(999);
clf(999)
tiledlayout('flow');

for i = 1:numel(C)
    
    % compute neurometric_dprime
    [dp,v] = C(i).neurometric_dprime(par);
    
    % fit the data with a sigmoidal function
    [xfit,yfit,p_val] = fit_sigmoid(v,dp);
    
    
    
    
    C(i).neurodprime.dprime = dp;
    C(i).neurodprime.vals   = v;
    C(i).neurodprime.xfit   = xfit;
    C(i).neurodprime.yfit   = yfit;
    C(i).neurodprime.p_val  = p_val;
    
    
    
    
    nexttile
    
    plot(v,dp,'--o', ...
        xfit,yfit,'-k');
    
    
    xlabel(par.event)
    ylabel('d''')
    title({C(i).Session.Name; ...
           C(i).TitleStr; ...
           sprintf('\\it{p = %g}',p_val)});
    
    grid on
end

ax = findobj(gcf,'type','axes');
c = cell2mat(get(ax,'ylim'));
set(ax,'ylim',[min(c(:)) max(c(:))]);

%%

% Since the array C is only of handles to the orignal Cluster objects,
% the original Cluster objects are already updated.
S_AM(1).Clusters(1).neurodprime













