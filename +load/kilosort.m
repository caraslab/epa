function S = kilosort(DataPath)
% S = kilosort(DataPath)
% 
% ex:   DataPath = 'C:\Path\To\Sorted\Data\';
%       S = epa.kilosort(DataPath);
% 
% Returns an array of Session object (S) derived from the DataPath, where
% DataPath is an array with one or more strings (or cell array of strings)
% pointing to the root directory of the Kilosort data output.
% 
% Important note: This function looks for files located under DataPath that
% have similar names. These names are derived from the first column within
% the '*concat_breakpoints.csv' file.
% 
% Expected files at the DataPath location:
%   config.mat 
%       > expected to have a structure variable called 'ops'
%   *concat_breakpoints.csv
%   *concat_cluster*.txt
%       > searched for exhaustively through all subdirectories
%   *trialInfo.csv
%       > searched for exhaustively through all subdirectories
% 
% Note that the asterisk, '*', is a wildcard that can stand for any string.
% 
% 
% DJS 2021

epa.helper.add_paths;

DataPath = char(DataPath);



%%
% load config file contains acquisition parameters
load(fullfile(DataPath,'config.mat'),'ops')




% determine spike breakpoints (in samples) from csv file
d = dir(fullfile(DataPath,'*concat_breakpoints.csv'));
ffn = fullfile(d.folder,d.name);
fid = fopen(ffn,'r');
bp = textscan(fid,'%s %d','delimiter',',','HeaderLines',1);
fclose(fid);
BPfileroot = cellfun(@(a) a(1:find(a=='_')-1),bp{1},'uni',0);
BPsamples  = [0; bp{2}];

% load spike clusters with spike times (in secconds) from txt files
d = dir(fullfile(DataPath,['**' filesep '*concat_cluster*.txt']));
ffn = cellfun(@fullfile,{d.folder},{d.name},'uni',0);
ST  = cellfun(@dlmread,ffn,'uni',0);
ST  = cellfun(@(a) cast(ops.fs*a,'like',BPsamples),ST,'uni',0);

clusterAlias = cellfun(@(a) a(find(a == '_',1,'last')+1:find(a=='.',1,'last')-1),ffn,'uni',0);

% Create a Session object for each recording block,
% split up spiketimes into sessions based on breakpoints
for i = 1:length(BPfileroot)
    S(i) = epa.Session(ops.fs);
    S(i).Name = BPfileroot{i};
    for j = 1:length(BPsamples)
        ind = ST{j} > BPsamples(i) & ST{j} <= BPsamples(i+1);
        xx = ST{j}(ind) - BPsamples(i); % recording block starts at 0 seconds
        if isempty(xx), continue; end
        S(i).add_Cluster(S(i).NClusters+1,xx);
        S(i).Clusters(end).Type = "SU"; % mark as single unit
        S(i).Clusters(end).Name = clusterAlias{j};
    end
end




%% Read Events from CSV files with event information
d = dir(fullfile(DataPath,['**' filesep '*trialInfo.csv']));

if isempty(d)
    warning(sprintf('No *trialInfo.csv files were found on the DataPath: "%s"',DataPath));
end

onsetEvent  = 'Trial_onset';
offsetEvent = 'Trial_offset';

for i = 1:length(S)
    c = contains(string({d.name}),S(i).Name);
    
    if ~any(c), continue; end
    
    
    fprintf('Adding Events from file for "%s" ...',S(i).Name);
    
    fid = fopen(fullfile(d(c).folder,d(c).name),'r');
    dat = {};
    while ~feof(fid), dat{end+1} = fgetl(fid); end
    fclose(fid);
    
    c = cellfun(@epa.helper.tokenize,dat,'uni',0);
    dat = cellfun(@matlab.lang.makeValidName,c{1},'uni',0);
    c(1) = [];
    v = cellfun(@str2double,c,'uni',0);
    v = cat(2,v{:})';
    
    
    % Event timings for these files are the same for all events
    ind = ismember(dat,onsetEvent);
    evOns = v(:,ind);
    dat(ind) = []; v(:,ind) = [];
    
    ind = ismember(dat,offsetEvent);
    evOffs = v(:,ind);
    dat(ind) = []; v(:,ind) = [];
    
    % Add each field as an Event
    for j = 1:length(dat)
        S(i).add_Event(dat{j},[evOns evOffs],v(:,j));
    end
    
    fprintf(' done\n')
end

