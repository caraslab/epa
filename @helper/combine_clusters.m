function cc = combine_clusters(varargin)

assert(all(cellfun(@(a) isa(a,'epa.Cluster'),varargin)), ...
    'epa:helper:combine_clusters:InvalidType', ...
    'All inputs must be of type epa.Cluster')


cc = varargin{1};
for i = 2:length(varargin)
    cc.Samples = [cc.Samples; varargin{i}.Samples];
    cc.Waveforms = cat(3,cc.Waveforms,varargin{i}.Waveforms);
end
cc.Samples = sort(cc.Samples);