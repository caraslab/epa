classdef Spikes < handle
    properties
        Name            (1,1) string
        Waveforms       (:,:,:) single % [channels x samples x spikes]
        Samples         (:,1) single {mustBeInteger} = [] % single datatype for easier manipulation
        Window          (1,2) double {mustBeFinite} = [0 1]
        SamplingRate    (1,1) double {mustBePositive} = 1
        Channels        (1,:) double {mustBeInteger,mustBeNonnegative,mustBeFinite} = []
        PrimaryChannel  (1,1) double {mustBeInteger,mustBeNonnegative,mustBeFinite} = 0
        ShankID         (1,1) double {mustBeInteger,mustBeNonnegative,mustBeFinite} = 0
        
        OriginalDataFile (1,1) % could be filename or struct from dir()
        
        parent
    end
    
    
    properties (Dependent)
        mean
        std
        Time
        SpikeTimes
        nSamples
        nChannels
        nSpikes
        primaryChannelIdx
    end
    
    properties (Constant)
        WaveformDims = 'Channels x Samples x Spikes';
    end
    
    methods
        
        function obj = Spikes(parent)
            if nargin == 1, obj.parent = parent; end
        end
        
        function set.Samples(obj,s)
            if ~isempty(obj.Waveforms)
                assert(numel(s) == obj.nSpikes, ...
                    'epa:SpikeWaveforms:Samples:UnequalDimensions', ...
                    'Number of Samples must equal the number of spikes')
            end
            obj.Samples = s(:);
        end
        
        function set.Waveforms(obj,w)
            if ~isempty(obj.Samples)
                assert(size(w,3) == length(obj.Samples), ...
                    'epa:SpikeWaveforms:Waveforms:UnequalDimensions', ...
                    'Size of dimension 3 of Waveforms must equal the number of Samples')
            end
            
            if isempty(obj.Channels)
                obj.Channels = 1:size(w,1);
            else
                assert(size(w,1) == numel(obj.Channels), ...
                    'epa:SpikeWaveforms:Waveforms:UnequalDimensions', ...
                    'Size of dimension 2 of Waveforms must equal the number of Channels')
            end
            
            obj.Waveforms = w;
        end
        
        
        function set.Channels(obj,ch)
            assert(numel(unique(ch)) == numel(ch), ...
                'epa:SpikeWaveforms:Channels:RepeatedValues', ...
                'All values of Channels must be unique')
            
            if ~isempty(obj.Waveforms)
                assert(size(obj.Waveforms,1) == numel(ch), ...
                    'epa:SpikeWaveforms:Channels:UnequalDimensions', ...
                    'Size of dimension 2 of Waveforms must equal the number of Channels')
            end
            
            obj.Channels = ch;
        end
        
        
        
        
        
        
        
        function t = get.SpikeTimes(obj)
            t = obj.Samples/obj.SamplingRate;
        end
        
        
        function t = get.Time(obj)
            if any(isnan(obj.Window))
                t = 0:obj.nSamples-1;
            else
                t = linspace(obj.Window(1),obj.Window(2),obj.nSamples);
            end
        end
        
        
        function n = get.nChannels(obj)
            n = size(obj.Waveforms,1);
        end
        
        function n = get.nSamples(obj)
            n = size(obj.Waveforms,2);
        end
        
        function n = get.nSpikes(obj)
            n = size(obj.Waveforms,3);
        end
        
        function i = get.primaryChannelIdx(obj)
            i = obj.channel_idx(obj.PrimaryChannel);
        end
        
        function i = channel_idx(obj,ch)
            i = ismember(obj.Channel,ch);
        end
        
        
        function h = plot_mean(obj,ax)
            if nargin < 2 || isempty(ax), ax = gca; end
            w = squeeze(obj.Waveforms(obj.primaryChannelIdx,:,:));
            m = obj.mean(obj.primaryChannelIdx,:);
            
            plot(ax,obj.Time*1e3,m,'-k','linewidth',2);
            grid(ax,'on');
            xlabel(ax,'time (ms)');
            
        end
        
        
        function h = plot_density(obj,ax)
            if nargin < 2 || isempty(ax), ax = gca; end
            
            w = squeeze(obj.Waveforms(obj.PrimaryChannel,:,:));
            
            xb = 1:size(w,1);
            yb = linspace(-250,250,40);
            
            x = repmat(xb',size(w,2),1);
            y = w(:);
            h = histogram2(ax,x,y,xb,yb, ...
                'normalization','pdf', ...
                'displaystyle','tile', ...
                'ShowEmptyBins','on', ...
                'EdgeAlpha',0);
            ax.CLim = quantile(h.Values(:),[.05 .95]);
            colorbar(ax);
            colormap(ax,parula);
        end
    end
    
end