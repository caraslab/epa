classdef Cluster < handle & dynamicprops
    % C = epa.Cluster(SessionObj,[ID],[Spiketimes],[SpikeWaveforms])
    
    
    properties
        ID       (1,1) uint16 {mustBeFinite} = -1;
        Name     string
        Type     string {mustBeMember(Type,["SU","MSU","MU","Noise",""])} = ""
        
        SamplingRate    (1,1) double {mustBePositive,mustBeFinite} = 1 % by default same as obj.Session.SamplingRate
               
        Channel         (1,1) double {mustBeFinite,mustBeInteger} = -1;
        Shank           (1,1) double {mustBePositive,mustBeFinite,mustBeInteger} = 1;
        ElectrodeType   (1,1) string
        Coords          (1,3) double {mustBeFinite} = [0 0 0];
        Waveforms       (:,:,:) single % [channels x samples x spikes]
        Samples         (:,1) single {mustBeInteger} = [] % single datatype for easier manipulation
        WaveformWindow  (1,2) double {mustBeFinite} = [0 1]
        ShankChannels   (1,:) double {mustBeInteger,mustBeNonnegative,mustBeFinite} = []
        ShankID         (1,1) double {mustBeInteger,mustBeNonnegative,mustBeFinite} = 0
        
        OriginalDataFile (1,1) % could be filename or struct from dir()
        
        
        Note     (:,1) string   % User notes
        UserData
        
        TitleStr (1,1) string   % auto generated if empty
    end
    
    
    properties (Dependent)
        SpikeTimes     % array of spike times from beginning of recording
        N              % spike count
        nSpikes        % same as obj.N
        nWaveformSamples
        nChannels
        channelInd
        WaveformTime
    end
    
    properties (SetAccess = immutable)
        Session      (1,1) %epa.Session
    end
    
    
    methods
        [t,eidx,vid]    = eventlocked(obj,varargin)
        [trials,V,eidx] = triallocked(obj,varargin)
        [c,b,v]         = psth(obj,varargin)
        [dprime,vals,M,V] = neurometric_dprime(obj,varargin)
        [n,lags]        = interspike_interval(obj,varargin)
        [r,lags]        = xcorr(obj,varargin)
        
        function obj = Cluster(SessionObj,ID,Samples)
            
            if nargin >= 1 && ~isempty(SessionObj), obj.Session = SessionObj; end
            if nargin >= 2 && ~isempty(ID),         obj.ID = ID;              end
            if nargin == 3 && ~isempty(Samples),    obj.Samples = Samples;    end
            
            obj.SamplingRate = obj.Session.SamplingRate;
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
            
            if isempty(obj.ShankChannels)
                obj.ShankChannels = 1:size(w,1);
            else
                assert(size(w,1) == numel(obj.ShankChannels), ...
                    'epa:SpikeWaveforms:Waveforms:UnequalDimensions', ...
                    'Size of dimension 2 of Waveforms must equal the number of ShankChannels')
            end
            
            obj.Waveforms = w;
        end
        
        
        function set.ShankChannels(obj,ch)
            assert(numel(unique(ch)) == numel(ch), ...
                'epa:SpikeWaveforms:ShankChannels:RepeatedValues', ...
                'All values of ShankChannels must be unique')
            
            if ~isempty(obj.Waveforms)
                assert(size(obj.Waveforms,1) == numel(ch), ...
                    'epa:SpikeWaveforms:ShankChannels:UnequalDimensions', ...
                    'Size of dimension 2 of Waveforms must equal the number of ShankChannels')
            end
            
            obj.ShankChannels = ch;
        end
        
        
        
        
        
        
        function t = get.WaveformTime(obj)
            if any(isnan(obj.WaveformWindow))
                t = 0:obj.nSpikes-1;
            else
                w = obj.WaveformWindow;
                t = w(1):1/obj.SamplingRate:w(2);
            end
        end
        
        function n = get.nChannels(obj)
            n = size(obj.Waveforms,1);
        end
        
        function n = get.nWaveformSamples(obj)
            n = size(obj.Waveforms,2);
        end
        
        function i = get.channelInd(obj)
            i = obj.ShankChannels == obj.Channel;
        end
        
        function t = get.SpikeTimes(obj)
            t = obj.Samples/obj.SamplingRate;
        end
        
        function n = get.nSpikes(obj)
            n = obj.N;
        end
        
        function n = get.N(obj)
            n = length(obj.Samples);
        end
        
        
        function tstr = get.TitleStr(obj)
            if obj.TitleStr == ""
                tstr = sprintf('%s-%d[%d]',obj.Type,obj.ID,obj.N);
                if obj.Name ~= ""
                    tstr = sprintf('%s-%s',obj.Name,tstr);
                end
            else
                tstr = obj.TitleStr;
            end
        end
        
        function c = copy(obj)
            if numel(obj) > 1
                c = arrayfun(@copy,obj);
                return
            end
            p = epa.helper.obj2par(obj);
            c = epa.Cluster(p.Session);
            p = rmfield(p,'Session');
            epa.helper.par2obj(c,p);
        end
        
        
        
        
        
        
        function h = plot_waveform_mean(obj,ax)
            if nargin < 2 || isempty(ax), ax = gca; end
            
            if obj.nWaveformSamples == 0
                cla(ax);
                title(ax,[obj.TitleStr '- NO SPIKE WAVEFORMS'])
                return
            end
            
            w = squeeze(obj.Waveforms(obj.channelInd,:,:));
            m = mean(w,2);
            
            h = plot(ax,obj.WaveformTime*1e3,m,'-k','linewidth',2);
            xlim(ax,obj.WaveformTime([1 end])*1e3);
            grid(ax,'on');
            xlabel(ax,'time (ms)');
            
            
            ax.Title.String = obj.TitleStr;
            ax.Title.FontSize = 10;
            
            if nargout == 0, clear h; end
        end
        
        
        function h = plot_waveform_density(obj,ax,normalization)
            if nargin < 2 || isempty(ax), ax = gca; end
            if nargin < 3 || isempty(normalization), normalization = 'count'; end
            
            
            if obj.nWaveformSamples == 0
                cla(ax);
                title(ax,[obj.TitleStr '- NO SPIKE WAVEFORMS'])
                return
            end
            
            xb = 1e3 * obj.WaveformTime(:);
            x = repmat(xb,obj.nSpikes,1);
            
            y = squeeze(obj.Waveforms(obj.channelInd,:,:));
            q = quantile(y(:),[.001 .999]);
            yb = linspace(q(1),q(2),40);
            
            if isempty(y) || isempty(x)
                h = [];
                ax.Title.String = obj.TitleStr;
                ax.Title.FontSize = 10;
                return
            end
            
            [n,xe,ye] = histcounts2(x,y(:),xb,yb,'Normalization',normalization);

            h = imagesc(ax,xe,ye,n');
            ax.YDir = 'normal';
            
            xlabel(ax,'time (ms)');
            
            ax.Title.String = obj.TitleStr;
            ax.Title.FontSize = 10;
            
            ax.CLim = [0 quantile(n(:),.95)];
            colormap(ax,flipud(hot));
            hc = colorbar(ax);
            hc.YLabel.String = normalization;
            hc.Visible = 'off';
            
            if nargout == 0, clear h; end
        end
    end
end
                
                
