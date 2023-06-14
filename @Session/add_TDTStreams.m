function add_TDTStreams(S,TDTTankPath,varargin)
% NOT YET FUNCTIONAL

par = [];
par.channels = 0;
par.resample = {};

par = epa.helper.parse_params(par,varargin{:});




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
    
    data = TDTbin2mat(blockPth,'TYPE',4,'CHANNEL',par.channels);
    
    if ~isempty(par.resample)
        data = resample(data,par.resample{:});
    end
    
    
    eventInfo = data.epocs;
    eventNames = fieldnames(eventInfo);
    for i = 1:length(eventNames)
        e = eventInfo.(eventNames{i});
        onoffs = [e.onset e.offset];
        S(ind).add_Event(eventNames{i}, onoffs, e.data);
    end
    
end