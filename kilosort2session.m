function S = kilosort2session(DataPath,TDTTankPath)
% S = kilosort2session(DataPath,[TDTTankPath])
% 
% ex:   DataPath = 'C:\Path\To\Sorted\Data\';
%       S = epa.kilosort2session(DataPath);
% 
% ex:   TDTTankPath = 'C:\Path\To\TDTTank\';
%       S = epa.kilosort2session(DataPath,TDTTankPath);
% 
% Returns an array of Session object (S) derived from the DataPath, where
% DataPath is an array with one or more strings (or cell array of strings)
% pointing to the root directory of the Kilosort data output.
% 
% You may optionally specify a TDTTankPath which will add Event data
% directly from the TDT Tank found at the specified location.
% 
% Important note: This function looks for files located at DataPath and
% TDTTankPath (if specified) that have similar names. These names are
% derived from the first column within the '*concat_breakpoints.csv' file.
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
% If specified, the standard TDT data tank files
% (*.tin,*.tev,*.Tdx,*.Tbk,*.tnt,*.tsq) are expected. Note that other
% files, like *.sev do not need to be located there since only Event data
% is read by this function.  
% 
% 
% DJS 2021


DataPath = char(DataPath);

if nargin > 1 && ~isempty(TDTTankPath)
    TDTTankPath = char(TDTTankPath);
else
    TDTTankPath = [];
end


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
BPsamples  = bp{2};
BPtimes = double(BPsamples) ./ ops.fs;
BPtimes = [0; BPtimes]; % makes indexing spikes later easier


% load spike clusters with spike times (in secconds) from txt files
d = dir(fullfile(DataPath,['**' filesep '*concat_cluster*.txt']));
ffn = cellfun(@fullfile,{d.folder},{d.name},'uni',0);
ST  = cellfun(@dlmread,ffn,'uni',0);

clusterAlias = cellfun(@(a) a(find(a == '_',1,'last')+1:find(a=='.',1,'last')-1),ffn,'uni',0);

% Create a Session object for each recording block,
% split up spiketimes into sessions based on breakpoints
for i = 1:length(BPfileroot)
    S(i) = epa.Session(ops.fs);
    S(i).Name = BPfileroot{i};
    for j = 1:length(ST)
        ind = ST{j} > BPtimes(i) & ST{j} <= BPtimes(i+1);
        xx = ST{j}(ind) - BPtimes(i); % recording block starts at 0 seconds
        S(i).add_Cluster(j,xx);
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



if isempty(TDTTankPath), return; end

%% Read Events from TDT Tank
addpath(fullfile(epa.helper.rootdir,'+epa','TDTbin2mat'));

d = dir(fullfile(TDTTankPath,['**' filesep '*.Tbk']));
sn = cellstr([S.Name]);
for t = 1:length(d)    
    blockPth = d(t).folder;
    [~,blockName,~] = fileparts(d(t).name);
    
    ind = cellfun(@(a) contains(blockName,a),sn);
    
    assert(sum(ind) == 1,'epa:kilosort2ssession:InvalidTDTBlock', ...
        'Found %d TDT blocks matching "%s"',sum(ind),blockName)
       
    
    fprintf('Adding Events from TDT Tank for Session "%s" ...',S(ind).Name)
    
    data = TDTbin2mat(blockPth,'TYPE',2,'VERBOSE',0);
    
    eventInfo = data.epocs;
    eventNames = fieldnames(eventInfo);
    for i = 1:length(eventNames)
        e = eventInfo.(eventNames{i});
        onoffs = [e.onset e.offset];
        S(ind).add_Event(eventNames{i}, onoffs, e.data);
    end
    
end
