function [n,lags] = interspike_interval(obj,varargin)
% [n,lags] = interspike_interval(ClusterObj,par)
% [n,lags] = interspike_interval(ClusterObj,'Name',Value,...)
% interspike_interval(ClusterObj,...)
% 
% Compute interspike interval for Cluster object.
% 
% If no outputs are specified, then a interspike interval histogram will be
% plotted in the current axes.
% 
% Input Parameters
%   maxlag  ... [1x1] maximum lag in seconds. default = 0.1
%   binsize ... [1x1] histogram bin size in seconds. default = 0.001
%   plot    ... plot interspike interval histogram into the current axes.
% 
% Output
%   n       ... bin counts
%   lags    ... bin lag in seconds
% 
% DJS 2021


par = [];
par.maxlag = 0.1;
par.binsize = 0.001;
par.plot = false;

if isequal(varargin{1},'getdefaults'), n = par; return; end

par = epa.helper.parse_params(par,varargin{:});

mustBePositive(par.maxlag);
mustBeFinite(par.maxlag);


dst = diff(obj.SpikeTimes);
binvec = 0:par.binsize:par.maxlag;

[n,lags] = histcounts(dst,binvec);
lags(end) = [];

if nargout == 0 || par.plot
    plot_isi(obj,lags,n);    
end


function plot_isi(obj,lags,n)
ax = gca;

h = bar(ax,lags*1e3,n);
h.EdgeColor = 'none';
h.BarWidth = 1;

xlabel(ax,'lag (ms)');
ylabel(ax,'count');
title(ax,obj.TitleStr);

grid(ax,'on');

xlim(ax,lags([1 end])*1e3);

[m,i] = max(n); % mode

str{1} = sprintf('n < %g ms = %d',lags(2)*1e3,n(1));
str{2} = sprintf('mode = %d @ %g ms',m,1e3*lags(i));
t = text(ax,.95*1e3*lags(end),.95*max(ylim),str, ...
    'VerticalAlignment','top','HorizontalAlignment','right', ...
    'FontName','Consolas','BackgroundColor',ax.Color);



