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
%   complete ...   Optionally compute all comparisons for all combinations
%                  of eventvalue.  If true, then dprime and vals are
%                  returned as square matrices and referencevalue will be
%                  ignored. Default = false.
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
par.complete = false;
par.metric = @epa.metric.trial_firingrate;

if isequal(varargin{1},'getdefaults'), dprime = par; return; end

par = epa.helper.parse_params(par,varargin{:});

[trials,V] = triallocked(obj,par);


par.Fs = obj.SamplingRate;


if isempty(par.referencevalue)
    par.referencevalue = min(V);
end

if ~par.complete
    refInd = V == par.referencevalue;
end

dV = unique(V(:));
dV(dV == par.referencevalue) = []; % don't calculate reference value against itself

par.values = V(:);

M = feval(par.metric,trials,par);
M = M(:);


if par.complete
    dprime = nan(length(dV));
    for i = 1:length(dV)
        for j = i:length(dV)
            ind = dV(i) == V;
            refInd = dV(j) == V;
            data = [M(refInd); M(ind)]';
            tind = [false(1,sum(refInd)) true(1,sum(ind))];
            dprime(i,j) = epa.metric.neurometric_dprime(data,tind);
        end
    end
else
    dprime = nan(size(dV));
    for i = 1:length(dV)
        ind = dV(i) == V;
        data = [M(refInd); M(ind)]';
        tind = [false(1,sum(refInd)) true(1,sum(ind))];
        dprime(i) = epa.metric.neurometric_dprime(data,tind);
    end
end


