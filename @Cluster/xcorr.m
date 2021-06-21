function [r,lags] = xcorr(obj,varargin)
% [r,lags] = xcorr(ClusterObjs,par)
% [r,lags] = xcorr(ClusterObjs,'Name',Value,...)
% xcorr(ClusterObjs,...)
% 
% Compute spike train cross-correlations and auto-correlations.
% 
% If no outputs are specified, then cross-orrelations are plotted into the
% current axes.
% 
% Input Parameters
%   maxlag  ... [1x1] maximum lag in seconds. default = 0.1
%   binsize ... [1x1] histogram bin size in seconds. default = 0.001
%   plot    ... plot interspike interval histogram into the current axes.
% 
% Output
%   r       ... [MxNxP] cross-correlations, with M time lags, N and P the
%               number of Cluster objects.
%   lags    ... [Mx1] bin lag in seconds
% 
% 
% DJS 2021


par = [];
par.maxlag = 0.2;
par.binsize = 0.01;
par.plot = false;
par.scaleopt = 'coeff';

if isequal(varargin{1},'getdefaults'), r = par; return; end

par = epa.helper.parse_params(par,varargin{:});

% time -> samples
maxlag  = round(obj(1).SamplingRate*par.maxlag); 

s1 = inf;
s2  = -inf;
for i = 1:numel(obj)
    s1 = min([s1; obj(i).SpikeTimes]);
    s2 = max([s2; obj(i).SpikeTimes]);
end

binvec = 0:par.binsize:s2-s1;

n = numel(obj);
r = zeros(maxlag*2+1,n,n);
k = 1;
for i = 1:n
    ssi = histcounts(obj(i).SpikeTimes-s1,binvec);
    
    for j = 1:n
        ssj = histcounts(obj(j).SpikeTimes-s1,binvec);
               
        [r(:,k),lags] = xcorr(ssi,ssj,maxlag,par.scaleopt);
                
        k = k + 1;
    end
end

lags = lags./obj(1).SamplingRate;

if nargout == 0 || par.plot
    plot_xcorr(obj,lags,r);
end



function plot_xcorr(obj,lags,r)
clf;
ax = gca;

if size(r,2) == 1
    plot(ax,lags,r,'-k');
    grid(ax,'on');
    axis(ax,'tight');
    xlabel('lag (seconds)');
    title(obj.TitleStr);
    return
end


[m,n,p] = size(r);
mr = zeros(m*n,p);
r = r ./ max(abs(r(:)));
for i = 1:p
    mr(:,i) = i-1 + reshape(r(:,:,i),m*n,1);
end

dt = lags(end)-lags(1);
rlags = (lags(end):dt:dt*p) + lags(:);

seps = rlags(end,:);
zers = rlags(round(end/2)+1,:);

rlags = rlags(:);

plot(ax,rlags,mr,'k');
axis(ax,'tight');

hold(ax,'on');
hx = plot(ax,[seps; seps],ylim,'-','linewidth',0.5,'color',[0.6 0.6 0.6]);
hy = plot(ax,xlim,repmat(y,2,1),'-','linewidth',0.5,'color',[0.6 0.6 0.6]);
hz = plot(ax,[zers; zers],ylim,':','linewidth',0.5,'color',[0.6 0.6 0.6]);
hold(ax,'off');

uistack([hx; hy; hz],'bottom');









