function [dprime,dV,M,V] = neurometric_dprime(obj,varargin)
% [dprime,vals] = neurometric_dprime(ClusterObj,par)
% [dprime,vals] = neurometric_dprime(ClusterObj,'Name','Value',...)
% [dprime,vals,M,vals] = neurometric_dprime(ClusterObj, ...)
% 
% Compute neurometric d-prime for a Cluster object based on one ore more
% event target values compared to a reference value.
% 
% Parameters:
%   event   ...   The name of an Event object associated with the Cluster
%                 object or the Event object itself. This parameter must be
%                 specified.
%   eventvalue ... The event value(s) for which to calculate d-prime.
%                  Default = 'all'.
%   referencevalue ... The value for which to compute d-prime against.
%                      Default is selected as the smallest value from
%                      eventvalue.
%   window  ...    Specify the response window relative to the event onset
%                  over which to compute the Cluster firing rate.
%   metric  ...    Determines how to calculate the measure for trial data.
%                  This can be specified as a handle to a function that
%                  returns a single value for each element in a [Mx1] cell
%                  array of spike timestamps relative to the event onset.
%                  Any function specified must also accept the par
%                  structure as its second input.
%                  Default computes firing rate over the entire window.
% 
% Output:
%   dprime  ...     [Nx1] Result(s) of the d-prime calculation.
%   vals    ...     [Nx1] Event value(s) associated with the dprime output.
%   M       ...     [Mx1] Firing rates used for each trial.
%   V       ...     [Mx1] All Event value(s) for each trial.
% 
% 
% DJS 2021


par = [];
par.event = "";
par.eventvalue = 'all';
par.referencevalue = [];
par.window = [0 1];
par.metric = [];


par = epa.helper.parse_params(par,varargin{:});

[trials,V] = triallocked(obj,par);

if isempty(par.metric)
    dw = diff(par.window);
    M = cellfun(@(a) numel(a)./dw,trials);
else
    M = feval(par.metric,trials,par);
end

if isempty(par.referencevalue)
    par.referencevalue = min(V);
end

refInd = V == par.referencevalue;

dV = unique(V(:));
% uvals(uvals == par.referencevalue) = []; % might as well explicitly compute this

dprime = nan(size(dV));
for i = 1:length(dV)
    ind = dV(i) == V;
    data = [M(refInd); M(ind)]';
    tind = [false(1,sum(refInd)) true(1,sum(ind))];
    dprime(i) = epa.metric.neurometric_dprime(data,tind);
end




