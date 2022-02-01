function add_TDTEvents(obj,TDTTankPath,eventFilter)
% S.add_TDTEvents(TDTTankPath,[eventFilter])
% 
% Add Event data from TDT tank block(s) located at the TDTTankPath.
% 
% Works on a scalar or array of epa.Session objects.
% 
% ex:
% % first create a Session object
% DataPath = 'c:\Path\to\your\Tank';
% S = epa.kilosort2session(DataPath);
% 
% % Assume the TDT Tank is located in the same directory
% % Use all events except for 'Cam1'
% TDTTankPath = DataPath;
% S.add_TDTEvents(TDTTankPath,{'-Cam1'});
% 
% 
% The standard TDT data tank files (*.tin,*.tev,*.Tdx,*.Tbk,*.tnt,*.tsq)
% are expected. Note that other files, like *.sev do not need to be located
% there since only Event data is read by this function.  
% 
% DJS 2021

narginchk(2,3)

if nargin < 3, eventFilter = {}; end
eventFilter = cellstr(eventFilter);

d = dir(fullfile(TDTTankPath,['**' filesep '*.tsq']));
sn = cellstr([obj.Name]);
for t = 1:length(d)
    blockPth = d(t).folder;
    [~,blockName,~] = fileparts(d(t).name);
    
    ind = cellfun(@(a) contains(blockName,a),sn);
    
    if ~any(ind), continue; end % not found
    
    assert(sum(ind) == 1,'epa:kilosort2ssession:InvalidTDTBlock', ...
        'Found %d TDT blocks matching "%s"',sum(ind),blockName)
    
    
    fprintf('Adding Events from TDT Tank for Session "%s" ... ',obj(ind).Name)
    
    data = TDTbin2mat(blockPth,'TYPE',2,'VERBOSE',0);

    eventInfo = data.epocs;
    eventNames = fieldnames(eventInfo);
    if ~isempty(eventFilter)
        ind = startsWith(eventFilter,'-');
        eventNames(ismember(eventNames,eventFilter(ind))) = [];
        
    end
    for i = 1:length(eventNames)
        e = eventInfo.(eventNames{i});
        onoffs = [e.onset e.offset];
        obj(ind).add_Event(eventNames{i}, onoffs, e.data);
    end
    
end