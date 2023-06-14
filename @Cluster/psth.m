function [c,b,uv] = psth(obj,varargin)
% [c,b,uv] = obj.psth(par)
% 
% par is a structure:
%  normalization ... Determines how the histogram should be normalized:
%                   'count','firingrate','countdensity','probability','cumcount','cdf','pdf'
%                   default = 'count' (note that 'firingrate' is equivalent to 'countdensity')
%                   Note: normalization by 'firingrate' or 'countdensity'
%                   is automatically averaged using the number of
%                   presentations for each unique stimulus value.
%   
% Output:
%  c    ... histogram counts
%  b    ... histogram bins
%  v    ... values associated with histogram
% 
% 
% 
% DJS 2021


par.binsize    = 0.01;
par.eventvalue = 'all';
par.normalization = 'count';
par.window     = [0 1];

if isequal(varargin{1},'getdefaults'), c = par; return; end

par = epa.helper.parse_params(par,varargin{:});

[t,eidx,v] = obj.eventlocked(par);

uv = unique(v);

if length(par.window) == 1, par.window = sort([0 par.window]); end


if isequal(lower(par.normalization),'firingrate')
    par.normalization = 'countdensity';
end


b = par.window(1):par.binsize:par.window(2);
c = nan(length(uv), length(b)-1);
for i = 1:length(uv)
    ind = uv(i) == v;
    hc = histcounts(t(ind),b,'Normalization',par.normalization);
    if isequal(par.normalization,'countdensity')
        c(i,:) = hc ./ length(unique(eidx(ind)));
    else
        c(i,:) = hc;
    end
end
b(end) = [];
