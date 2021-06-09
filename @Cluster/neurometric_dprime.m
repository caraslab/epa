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
par.metric = @averagefr;


par = epa.helper.parse_params(par,varargin{:});

[trials,V] = triallocked(obj,par);


par.Fs = obj.SamplingRate;

M = feval(par.metric,trials,par);
M = M(:);

if isempty(par.referencevalue)
    par.referencevalue = min(V);
end

if ~par.complete
    refInd = V == par.referencevalue;
end

dV = unique(V(:));
% uvals(uvals == par.referencevalue) = []; % might as well explicitly compute this

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

end

function M = averagefr(trials,par)
    dw = diff(par.window);
    M = cellfun(@(a) numel(a)./dw,trials);
end

function M = tmtf(trials,par)
    
    if ~isfield(par,'binsize') || isempty(par.binsize)
        par.binsize = 0.01;
    end
    

    Fs = 1./par.binsize;
    
    tvec = par.window(1):par.binsize:par.window(2)-par.binsize;
    
    h = cellfun(@(a) histcounts(a,tvec,'Normalization','countdensity'),trials,'uni',0);
    h = cell2mat(h)';
    
    L = 2^nextpow2(size(h,1));
    Y = fft(h,L,1);
    P2 = abs(Y./L);
    P1 = P2(1:round(L/2)+1,:);
    P1(2:end-1,:) = 2*P1(2:end-1,:);
    f = Fs*(0:round(L/2))/L;

    
    [~,i] = min((f - par.modfreq).^2);
    M = mean(P1(i,:),1);
    
    
end