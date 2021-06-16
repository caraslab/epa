function [t,thr] = first_spike_latency(trials,varargin)
% t = first_spike_latency(ClusterObj,par)
% t = first_spike_latency(ClusterObj,'Name',value,...)
% [t,thr] = first_spike_latency(ClusterObj,...)
%
% Find latency to first spike of each trial constrained by par.minlag and
% par.maxlag.
% 
% Input Parameters
%   trials  ... [Nx1] cell array with spike latencies for each trial
% 
% par fields
%   minlag  ... [1x1] minimum lag to first spike in seconds. default = 0.001
%   maxlag  ... [1x1] maximum lag to first spike in seconds. default = 0.2
%   windur  ... [1x1] window duration for estimating lambda. default = 0.05
%   p_value ... [1x1] between 0 and 1 for computing threshold. default = 0.95
% 
% Output
%   t       ... first spike latency for each trial. returns as a matrix
%               the same size as trials. NaNs are returned where no spikes
%               are found after minlag and before maxlag.
% 
% DJS 2021


par = [];
par.minlag = 0.01;
par.maxlag = 0.2;
par.windur = 0.05;
par.p_value = 0.95;

par = epa.helper.parse_params(par,varargin{:});

mustBePositive([par.minlag par.maxlag]);
mustBeFinite([par.minlag par.maxlag]);

st = cell2mat(trials);

n = length(trials);

lambda = sum(st >= par.minlag-par.windur & st < par.minlag)./n;
thr = poissinv(par.p_value,lambda);



tvec = par.minlag:par.windur:par.maxlag;
ct = cell(n,1);
for i = 1:length(tvec)-1
    for j = 1:n
        ind = trials{j} >= tvec(i) & trials{j} < tvec(i+1);
        ct{j}(i) = sum(ind);
    end
end

t = nan(n,1);
for i = 1:n
    idx = find(ct{i} >= thr,1);
    
    if isempty(idx), continue; end
   
    fsb = tvec(idx);
    
    fsidx = find(trials{i}>=fsb,1);
    
    t(i) = trials{i}(fsidx);
end














