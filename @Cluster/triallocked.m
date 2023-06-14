function [trials,V,eidx] = triallocked(obj,varargin)
% [trials,V,eidx] = triallocked(obj,varargin)
% 
% Function is similar to eventlocked, but returns a cell array of spike
% times relative to event onsets.
% 
% Input:
%   event       ... char event name
%   eventvalue  ... specify event value(s) or 'all', default = 'all'
%   window      ... [1x2] window relative to event onset in seconds, or
%                   [1x1] window duration, default = 1
%   sorton      ... Determines how trials should be sorted. 'original' or
%                     'events'. 'events' orders the trials by event value.
% 
% 
% Output:
%   trials      ... [Mx1] cell array of spike times relative to the event
%                   onset.
%   V           ... [Mx1] array of values corresponding to the event value
%                   for each trial.
% 
% DJS 2021

par.event = [];
par.eventvalue = 'all';
par.window     = [0 1];
par.sorton     = 'events';

if isequal(varargin{1},'getdefaults'), trials = par; return; end

par = epa.helper.parse_params(par,varargin{:});

[t,eidx,v] = obj.eventlocked(par);

ue = unique(eidx);
trials = cell(size(ue));
V = nan(size(trials));
for i = 1:length(ue)
    ind = eidx == ue(i);
    trials{i} = t(ind);
    V(i) = v(find(ind,1));
end
eidx = ue;