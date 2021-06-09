%% Example: Compute neurometric dprime and add result as a new property to 
% the Cluster object


S_AM = [S.find_Session("Passive") S.find_Session("Aversive")];

% process all Clusters independently
C = [S_AM.Clusters];
% C = S_AM.find_Cluster("cluster582");
% C = [C{:}];

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
par.metric = 'tmtf';

% compute neurometric dprime for each Cluster independently
for i = 1:length(C)
    
    [dp,v] = C(i).neurometric_dprime(par); 
    
    C(i).neurodprime.dprime = dp;
    C(i).neurodprime.vals   = v;
end


% Since the array C is only of handles to the orignal Cluster objects,
% the original Cluster objects are already updated.
S_AM(1).Clusters(1).neurodprime


%% plot

figure
tiledlayout('flow');
for i = 1:length(S_AM)
    for j = 1:S(i).NClusters
        
        C = S_AM(i).Clusters(j);
        
        nexttile;
        plot(C.neurodprime.vals,C.neurodprime.dprime,'-o');
        xlabel(par.event)
        ylabel('d''')
        title({C.Session.Name; C.TitleStr});
        grid on
    end
end

%% fit

% x = 

