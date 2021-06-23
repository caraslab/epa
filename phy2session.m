function S = phy2session(DataPath,varargin)
% S = phy2session(DataPath)
%
% ex:   DataPath = 'C:\Path\To\Sorted\Data\';
%       S = epa.phy2session(DataPath);
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
%       > contains two columns and one header row. the first column
%       contains Session names and the second column contains
%       corresponding sample breakpoints indicating the end of the session.
%   *trialInfo.csv
%       > searched for exhaustively through all subdirectories
%   spike_times.npy    
%       > Vector of cluster spike times (in samples) same length as .spikeClusters
%   spike_clusters.npy
%       > Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes
%   channel_shanks.npy
%       > Vector of cluster shanks
%   channel_map.npy
%       > Contains channels mapped to electrode. This is important in esp if you got rid of files.
%   cluster_info.tsv
%       > A structure with cluster info 
% 
%   *.dat
%       > Data file contains all samples for all channels
%       > [Channels x Samples] uint64
%       > This file can be specified explicitly. default = '*.dat'
% 
% Note that the asterisk, '*', is a wildcard that can stand for any string.
%
%
% DJS 2021


par.includespikewaveforms = true;
par.spikewindow = [-0.5e-3 1.5e-3]; % seconds
par.groups      = ["SU" "MUA"];
par.datafilestr = '';

if isequal(DataPath,'getdefaults'), S = par; return; end

par = epa.helper.parse_params(par,varargin{:});


DataPath = char(DataPath);


% load config file contains acquisition parameters
load(fullfile(DataPath,'config.mat'),'ops')



fprintf('Loading spikes ')
Fs = ops.fs;

spikeSamples   = readNPY(fullfile(DataPath, 'spike_times.npy'));    % Vector of cluster spike times (in samples) same length as .spikeClusters
spikeClusters  = readNPY(fullfile(DataPath, 'spike_clusters.npy')); % Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes
channelShanks  = readNPY(fullfile(DataPath, 'channel_shanks.npy')); % Vector of cluster shanks
channelMap     = readNPY(fullfile(DataPath, 'channel_map.npy'));    % this is important in esp if you got rid of files.
clusterQuality = tdfread(fullfile(DataPath, 'cluster_info.tsv'));

if isempty(par.datafilestr)
    par.datafilestr = fullfile(DataPath,'*.dat');
end

d = dir(par.datafilestr);
datffn = fullfile(d.folder,d.name);

clusterQuality.group   = strtrim(string(clusterQuality.group));
clusterQuality.KSLabel = strtrim(string(clusterQuality.KSLabel));

% HARDCODE: Translate "good" to "SU" and make all groups uppercase
clusterQuality.group(clusterQuality.group=="good") = "SU";
clusterQuality.group = upper(clusterQuality.group);

nChannels = length(channelMap);

dataType = 'int16';

nbytes = numel(typecast(cast(0,dataType),'uint8'));

nSamples = d.bytes/(nChannels*nbytes); % # samples per channel

swWinSamps = round(Fs*par.spikewindow);
par.spikewindow = swWinSamps/Fs;
swvec      = swWinSamps(1):swWinSamps(2);
% split +/- samples in case of uint datatype
swvec_neg = cast(abs(swWinSamps(1):0),'like',spikeSamples);
swvec_pos = cast(1:swWinSamps(2),'like',spikeSamples);


mmf = memmapfile(datffn, 'Format', {dataType, [nChannels nSamples], 'x'});


groupIdx = find(ismember(clusterQuality.group,upper(par.groups)));

for j = 1:length(groupIdx)
    spikes(j) = structfun(@(a) a(groupIdx(j)),clusterQuality,'uni',0);
end

for j = 1:length(spikes)
    shankChannels = channelMap(channelShanks == spikes(j).sh);
    
    % find spike samples for this spike cluster indices 
    idx = find(spikes(j).cluster_id == spikeClusters);

    SW(j).Name          = string(sprintf('cluster%d',spikes(j).cluster_id));
    SW(j).Samples       = spikeSamples(idx);
    SW(j).SamplingRate  = Fs;
    SW(j).Window        = par.spikewindow;
    SW(j).Channels      = shankChannels;
    SW(j).PrimaryChannel = spikes(j).ch;
    SW(j).ShankID       = spikes(j).sh;
    SW(j).OriginalDataFile = dir(datffn);
    SW(j).Type          = spikes(j).group;
    
    if par.includespikewaveforms
        wf = zeros(length(shankChannels),length(swvec),spikes(j).n_spikes,dataType);
        for i = 1:length(idx)
            % uint: subtract earlier and add later samples
            sidx = [spikeSamples(idx(i))-swvec_neg, spikeSamples(idx(i))+swvec_pos];
            wf(:,:,i) = mmf.Data.x(shankChannels,sidx);
        end
        SW(j).Waveforms = cast(wf,'single'); clear wf
        fprintf('.')
    end
end

fprintf(' done\n')





% determine spike breakpoints (in samples) from csv file
d = dir(fullfile(DataPath,'*concat_breakpoints.csv'));
ffn = fullfile(d.folder,d.name);
fid = fopen(ffn,'r');
bp = textscan(fid,'%s %d','delimiter',',','HeaderLines',1);
fclose(fid);
BPfileroot = cellfun(@(a) a(1:find(a=='_')-1),bp{1},'uni',0);
BPsamples  = [0; bp{2}]; % makes indexing spikes later easier
BPsamples  = cast(BPsamples,'single'); 

% Create a Session object for each recording block,
% split up spiketimes into sessions based on breakpoints
for i = 1:length(BPfileroot)
    fprintf('Creating Session "%s" ',BPfileroot{i})
    S(i) = epa.Session(ops.fs);
    S(i).Name = BPfileroot{i};
    for j = 1:length(SW)
        ind = SW(j).Samples > BPsamples(i) & SW(j).Samples <= BPsamples(i+1);
        
        S(i).add_Cluster(j);
        C = S(i).Clusters(end);
        C.Name = SW(j).Name;
        C.Type = SW(j).Type;
        C.Samples = SW(j).Samples(ind);
        C.Channel = SW(j).PrimaryChannel;
        C.Shank   = SW(j).ShankID;
        C.ShankChannels = SW(j).Channels;
        C.WaveformWindow = SW(j).Window;
        C.OriginalDataFile = SW(j).OriginalDataFile;
        
        if par.includespikewaveforms
            C.Waveforms = SW(j).Waveforms(:,:,ind);
        end
        fprintf('.')
    end
    fprintf(' done\n')
end






% Read Events from CSV files with event information
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

