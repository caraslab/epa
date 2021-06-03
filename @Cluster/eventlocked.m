function [t,eidx,vid] = eventlocked(obj,varargin)
% [t,eidx,vid] = eventlocked(ClusterObj,par)
% [t,eidx,vid] = eventlocked(ClusterObj,'Name',Value,...)
%  
% Input:
%   eventname     ... char event name
%   eventvalue    ... specify event value(s) or 'all', default = 'all'
%   window        ... [1x2] window relative to event onset in seconds, or
%                     [1x1] window duration, default = 1
%   sorton          ... Determines how trials should be sorted. 'original' or
%                     'events'. 'events' orders the trials by event value.
% 
% 
% Output:
%   t    ...    [Nx1] Spike timestamps adjusted by the event onset within
%               the specified window.f
%   eidx ...    [Nx1] Indices of Events corresponding to each spikes in t
%   vid  ...    [Nx1] Values of Events corresponding to each spike in t
% 
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


switch lower(par.sorton)
    case 'events'
        [v,vidx] = sort(v);
        
    case 'original'
        vidx = 1:length(v);
        
    otherwise
        error('epa:Cluster:eventlocked','Unknown sorton method: ''%s''',par.sorton)
end
oot = oot(vidx);

if numel(par.window) == 1
    par.window = sort([0 par.window]);
end
par.window = par.window(:)';

twin = par.window + oot(:,1);


st = obj.SpikeTimes;

t = []; eidx = []; vid = [];
for i = 1:size(twin,1)
    ind = st >= twin(i,1) & st <= twin(i,2);
    if ~any(ind), continue; end
    t    = [t; st(ind)-oot(i,1)];
    eidx = [eidx; i*ones(sum(ind),1)];
    vid  = [vid; v(i)*ones(sum(ind),1)];
end





