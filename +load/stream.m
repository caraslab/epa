function stream(SessionObj,fullFilename,streamName,electrodeType)

narginchk(2,4)

assert(isa(SessionObj,'epa.Session'), ...
    'epa:load:stream:InvalidSessionObject', ...
    'First input must be a valid epa.Session object');

assert(isfile(fullFilename), ...
    'epa:load:stream:FileNotFound', ...
    'The file "%s" does not exist',fullFilename);
    

if nargin < 3 || isempty(streamName), streamName = "stream"; end
if nargin < 4 || isempty(electrodeType), electrodeType = 'Generic'; end

if ischar(electrodeType) || isstring(electrodeType)
    electrodeType = epa.electrodes.(electrodeType);
end

streamName = string(streamName);

fprintf('Loading "data" and "info" from "%s" ...',fullFilename)
load(fullFilename,'data','info')
fprintf(' done\n')

S = SessionObj;

if numel(S.Electrodes) > 1
    S.Electrodes(end+1) = electrodeType;
else
    S.Electrodes = electrodeType; % must be initialized for first index
end

for i = 1:size(data,2)
    S.add_Stream(streamName,i,data(:,i));
end

set(S.Streams,'SamplingRate',info.sampleRate,'ElectrodeIndex',length(S.Electrodes));





