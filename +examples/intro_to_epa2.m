%% load data from one day with one or multiple sessions into a new "Session" object

% DataPath = 'C:\Users\Daniel\Documents\MATLAB\TestEPhysData\SUBJ-ID-202\210613_concat';
DataPath = '/mnt/CL_4TB_2/Rose/IC recording/SUBJ-ID-202/210611_concat';

S = epa.load.phy(DataPath);


TDTTankPath = '/mnt/CL_4TB_2/Rose/IC recording/SUBJ-ID-202/210611_concat';

S.add_TDTEvents(TDTTankPath);



%% Save Session object(s) to quickly load for later analysis
% Since Matlab uses compression for saved .mat files, the original data
% total file size went from > 8GB to ~256 MB on disk

% dataFilename = 'C:\Users\Daniel\Documents\MATLAB\TestEPhysData\SUBJ-ID-202\Session_210613_concat.mat';
dataFilename = '/mnt/CL_4TB_2/Daniel/ExampleData/210611_concat.mat';

save(dataFilename,'S');

%% Reload saved Session object(s) from .mat file takes only a few seconds :)

% dataFilename = 'C:\Users\Daniel\Documents\MATLAB\TestEPhysData\SUBJ-ID-202\Session_210613_concat.mat';
dataFilename = '/mnt/CL_4TB_2/Daniel/ExampleData/210611_concat.mat';

load(dataFilename)

%% The DataBrowser GUI is useful for quickly accessing Session data

D = epa.DataBrowser;