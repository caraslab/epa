function [data,eidx,v,swin] = eventlocked(obj,varargin)
% [data,eidx,v,swin] = eventlocked(StreamObj,par)
% [data,eidx,v,swin] = eventlocked(StreamObj,'Name',Value,...)
%  
% Input:
%   eventname     ... char event name
%   eventvalue    ... specify event value(s) or 'all', default = 'all'
%   window        ... [1x2] window relative to event onset in seconds, or
%                     [1x1] window duration, default = 1
%   sorton        ... Determines how trials should be sorted. 'original' or
%                     'events'. 'events' orders the trials by event value.
% 
% 
% Output:
%   data ...    [NxP] Streamly sampled data with N trials and P
%               samples.
%   eidx ...    [Nx1] Indices of Events corresponding to each trial in data
%   vid  ...    [Nx1] Values of Events corresponding to each trial in data
%   swin ...    [NxP] Samples matching data output
% 
% DJS 2021


par.eventvalue = 'all';
par.window     = [0 1];
par.sorton     = 'events';

par = epa.helper.parse_params(par,varargin{:});

mustBeNonempty(par.event);

if ~isa(par.event,'epa.Event')
    par.event = obj.Session.find_Event(par.event);
end

E = par.event; % copy handle to Event object


[v,oot] = E.subset(par.eventvalue);

oos = uint64(oot .* obj.SamplingRate); % time -> samples

switch lower(par.sorton)
    case 'events'
        [v,vidx] = sort(v);
        
    case 'original'
        vidx = 1:length(v);
        
    otherwise
        error('epa:Stream:eventlocked','Unknown sorton method: ''%s''',par.sorton)
end
oos = oos(vidx);
oos = oos(:);

if numel(par.window) == 1
    par.window = sort([0 par.window]);
end
par.window = par.window(:)';

swin = uint64(par.window .* obj.SamplingRate); % time -> samples

swin = oos(:,1) + (swin(1):swin(end));

ind = swin<1|swin>obj.N;
swin(ind) = nan;

data = obj.Data(swin);
data = data(vidx,:);

eidx = zeros(size(swin,1),1);
uv = unique(v);
for i = 1:length(uv)
    ind = v == uv(i);
    eidx(ind) = i;
end












