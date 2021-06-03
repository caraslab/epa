%% Create a new Session object(s)


DataPath = '/mnt/CL_4TB_2/Rose/IC recording/SUBJ-ID-228-210219-122948/Organized/210223_concat_organized';

% TDTTankPath = DataPath;
S = epa.kilosort2session(DataPath,TDTTankPath);

%% DataBrowser GUI finds valid Session objects in the base workspace

D = epa.DataBrowser;

%% Access currently selected data in the DataBrowser

C = D.curClusters

E1 = D.curEvent1
E2 = D.curEvent2

E1vals = D.curEvent1Values
E2vals = D.curEvent2Values

curSession = D.curSession





%% we can use S.find_Session to return a Session based on a substring

% find and return the "Passive-Post-210227-125506" session
Spost = S.find_Session("Post"); 

% Note that the handle to the Session object is returned so no data is
% copied. Modifying Spost is the same as modifying S(3)
isequal(Spost,S(3))

Spost.Clusters(1)


%% Example 1a - Using 'Name,Value' paired input

C = Spost.Clusters(3);

% h = epa.plot.PSTH_Raster(C,'event',"AMdepth");
h = epa.plot.PSTH(C,'event',"AMdepth");

% you can also set properties after creating the plot object
h.eventvalue = 0.5;

h.plot;

%% Update the existing plot
h.window = [-0.2 1];

%% Change the plot color
h.colormap = [.26 .53 .96];

%% Stop/Start listening to changes
h.listenforchanges = false;


%% Save your figure 
save('MyFigure.mat','h');

%% Reload the figure with all object info
load('MyFigure.mat')

disp(h)
figure;
h.plot




% %%
% 
% Sam = S(1:3);
% 
% 
% C = [Sam(:).Clusters];
% 
% par = [];
% par.event = "AMdepth";
% par.window = [0 1];
% 
% for i = 1:length(C) 
%     [t,eidx,v] = C(i).eventlocked(par);
%     
%     uv = unique(v);
%     uv(uv==0) = [];
%     
%     refI
%     
%     for j = 1:length(uv)
%         ind = uv(j) == v;
%         data = t(ind)
%         dp(j) = epa.metric.neurometric_dprime(
%     end
% end
% 
% 
% % epa.metric.neurometric_dprime
% 






