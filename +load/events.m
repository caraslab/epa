function events(S,DataPath)
% events(S,DataPath)
% 
% Read Events from CSV files ('*trialInfo.csv') with event information.
% Events will be added to the Session object(s), S.
% 
% DJS 2021

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

