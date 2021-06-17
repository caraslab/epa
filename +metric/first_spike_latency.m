function [t,thr,lambda] = first_spike_latency(trials,varargin)
% t = first_spike_latency(ClusterObj,par)
% t = first_spike_latency(ClusterObj,'Name',value,...)
% [t,thr,lambda] = first_spike_latency(ClusterObj,...)
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
%   thr     ... estimated threshold based on Poisson distribution with mean
%               lambda.
%   lambda  ... mean firing rate computed over all trials from windur just
%               prior to minlag. 
% DJS 2021


par.minlag = 0.05;
par.maxlag = 0.25;
par.windur = 0.005;
par.p_value = 0.95;

par = epa.helper.parse_params(par,varargin{:});

mustBePositive([par.minlag par.maxlag]);
mustBeFinite([par.minlag par.maxlag]);

t = nan(size(trials));

tvec = par.minlag:par.windur:par.maxlag;
    
uv = unique(par.values);

st = cell2mat(trials);

% average spike count preceeding minimum lag
lambda = sum(st >= par.minlag-par.windur & st < par.minlag)./length(trials);

% threshold assuming poisson distribution with mean of lambda
thr = poissinv(par.p_value,lambda);


for k = 1:length(uv)
    ind = par.values == uv(k);
    n = sum(ind);

    kidx = find(ind);
    
    ktrials = trials(ind);
    
    
    
    % bin spikes by par.windur between par.minlag and par.maxlag
    ct = cell(n,1);
    for i = 1:length(tvec)
        for j = 1:n
            ind = ktrials{j} >= tvec(i) & ktrials{j} < tvec(i)+par.windur;
            ct{j}(i) = sum(ind);
        end
    end
    
    for i = 1:n
        % find earliest bin with spike count greater than or equal to threshold
        idx = find(ct{i} >= thr,1);
        
        if isempty(idx), continue; end
        
        % first spike bin
        fsb = tvec(idx);
        
        % first spike within bin
        fsidx = find(ktrials{i}>=fsb&ktrials{i}<par.maxlag,1);
        
        if isempty(fsidx), continue; end
        
        t(kidx(i)) = ktrials{i}(fsidx);
    end
    
end












