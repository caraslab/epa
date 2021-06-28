classdef Cluster < epa.DataInterface
    % C = epa.Cluster(SessionObj,[ID],[Spiketimes],[SpikeWaveforms])
    
    
    properties
        ID       (1,1) uint16 {mustBeFinite} = 0;
        Type     string {mustBeMember(Type,["SU","MSU","MU","Noise",""])} = ""
        
        SamplingRate    (1,1) double {mustBePositive,mustBeFinite} = 1 % by default same as obj.Session.SamplingRate
               
        Channel         (1,1) double {mustBeFinite,mustBeInteger} = -1;
        Shank           (1,1) double {mustBePositive,mustBeFinite,mustBeInteger} = 1;
        ElectrodeType   (1,1) string
        Coords          (:,3) double {mustBeFinite} = [0 0 0];
        Waveforms       (:,:,:) single % [channels x samples x spikes]
        Samples         (:,1) single {mustBeInteger} = [] % single datatype for easier manipulation
        WaveformWindow  (1,2) double {mustBeFinite} = [0 1]
        ShankChannels   (1,:) double {mustBeInteger,mustBeNonnegative,mustBeFinite} = []
        ShankID         (1,1) double {mustBeInteger,mustBeNonnegative,mustBeFinite} = 0
        
        OriginalDataFile (1,1) % could be filename or struct from dir()
        
        
        Note     (:,1) string   % User notes
        
        TitleStr (1,1) string   % auto generated if empty
    end
    
    
    properties (Dependent)
        SpikeTimes     % array of spike times from beginning of recording
        nSpikes        % same as obj.N
        nWaveformSamples
        nChannels
        channelInd
        WaveformTime
        N
    end
    
    
    events
        Updated
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
            
        end
        
        function fs = get.SamplingRate(obj)
            if isempty(obj.Session)
                obj.SamplingRate = 1;
            else
                obj.SamplingRate = obj.Session.SamplingRate;
            end
            fs = obj.SamplingRate;
        end
        
        
%         function set.Samples(obj,s)
%             if ~isempty(obj.Waveforms)
%                 assert(numel(s) == obj.nSpikes, ...
%                     'epa:SpikeWaveforms:Samples:UnequalDimensions', ...
%                     'Number of Samples must equal the number of spikes')
%             end
%             obj.Samples = s(:);
%         end
        
        function set.Waveforms(obj,w)
%             if ~isempty(obj.Samples)
%                 assert(size(w,3) == length(obj.Samples), ...
%                     'epa:SpikeWaveforms:Waveforms:UnequalDimensions', ...
%                     'Size of dimension 3 of Waveforms must equal the number of Samples')
%             end
            
%             if isempty(obj.ShankChannels)
%                 obj.ShankChannels = 1:size(w,1);
%             else
%                 assert(size(w,1) == numel(obj.ShankChannels), ...
%                     'epa:SpikeWaveforms:Waveforms:UnequalDimensions', ...
%                     'Size of dimension 2 of Waveforms must equal the number of ShankChannels')
%             end
            
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
        
        
        
        function h = edit(obj,src,event)
            pos = getpref('epa_ClusterEditor','Position',[150 150 900 500]);
            f = figure('Color','w','Position',pos);
            f.Pointer = 'watch'; drawnow
            movegui(f,'onscreen');
            h = epa.ClusterEditor(obj,f);
            f.CloseRequestFcn = {@epa.helper.store_obj_pref,'epa_ClusterEditor','Position',@delete};
            f.Pointer = 'arrow';
            if nargout == 0, clear h; end
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
            tstr = sprintf('%s-%s-%d[%d]',obj.Name,obj.Type,obj.ID,obj.N); 
            tstr = string(tstr);
        end
        
        
        
        
        
        
        function rem_spikes(obj,s)
            % obj.rem_spikes(samples)
            % 
            % Remove one or more spikes from the Cluster using the spike
            % sample (obj.Samples).
            ind = ismember(obj.Samples,s);
            obj.Waveforms(:,:,ind) = [];
            obj.Samples(ind) = [];
            notify(obj,'Updated');
        end
        
        
        function [coeff,score,latent,tsquared,explained,mu] = waveform_pca(obj)
            w = reshape(obj.Waveforms,obj.nChannels*obj.nWaveformSamples,obj.nSpikes);
            [coeff,score,latent,tsquared,explained,mu] = pca(w');
        end
        
        
        function h = plot_interspike_interval(obj,ax,varargin)
            if nargin < 2 || isempty(ax), ax = gca; end
            if nargin < 3, varargin = {}; end
            
            par = [];
            par.maxlag = 0.1;
            par.binsize = 0.5e-3;
            par.rpvthreshold = 1.5e-3; % ms; refractory period violations threshold
            
            if nargin > 1 && isequal(ax,'getdefaults'), h = par; return; end
            
            par = epa.helper.parse_params(par,varargin{:});
            
            ind = diff(obj.SpikeTimes) < par.rpvthreshold;
            rpvc = sum(ind);
            
            [n,lags] = obj.interspike_interval(par);
            
            ind = lags < par.rpvthreshold;
            
            cla(ax,'reset');
            hold(ax,'on');
            h.isi = bar(ax,1e3*lags,n,'BarWidth',1,'EdgeColor','none','FaceColor','k');
            h.rpv = bar(ax,1e3*lags(ind),n(ind),'BarWidth',1,'EdgeColor','none','FaceColor','r');
%             h.rpvthreshold = line(ax,[1 1]*par.rpvthreshold*1e3,ylim(ax),'Color','r');
            hold(ax,'off');
            
            grid(ax,'on');
            ax.Title.String = obj.TitleStr;
            ax.YAxis.Label.String = 'count';
            ax.XAxis.Label.String = 'inter-spike interval (ms)';
            ax.XLim = lags([1 end])*1e3;
            

            
            str{1} = sprintf('n < %g ms = %d',par.rpvthreshold*1e3,rpvc);

            t = text(ax,.95*1e3*lags(end),.95*max(ylim),str, ...
                'VerticalAlignment','top','HorizontalAlignment','right', ...
                'FontName','Consolas','BackgroundColor',ax.Color);

            epa.helper.setfont(ax);

            if nargout == 0, clear h; end
        end
        
        
        function h = plot_waveforms(obj,ax,maxw)
            if nargin < 2 || isempty(ax), ax = gca; end
            if nargin < 3 || isempty(maxw), maxw = 1000; end
            
            if obj.nWaveformSamples == 0
                cla(ax);
                title(ax,[obj.TitleStr '- NO SPIKE WAVEFORMS'])
                return
            end
            
            maxw = min(obj.nSpikes,maxw);
            
            idx = randperm(obj.nSpikes,maxw);
            idx = sort(idx);
            
            w = squeeze(obj.Waveforms(obj.channelInd,:,idx));

            
            for i = 1:length(idx)
                h(i) = line(ax,1e3*obj.WaveformTime,w(:,i), ...
                    'color',[.4 .4 .4], ...
                    'UserData',obj.Samples(idx(i)));
            end
            
            xlim(ax,obj.WaveformTime([1 end])*1e3);
            
            grid(ax,'on');
            box(ax,'on');
            
            xlabel('time (ms)');
            
            title(ax,obj.TitleStr);
            
            epa.helper.setfont(ax);
            
            if nargout == 0, clear h; end
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
            title(ax,obj.TitleStr);

            epa.helper.setfont(ax);
            
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
                epa.helper.setfont(ax);
                return
            end
            
            [n,xe,ye] = histcounts2(x,y(:),xb,yb,'Normalization',normalization);

            n = interp2(n,2);
            h = imagesc(ax,xe,ye,n');
            h.ButtonDownFcn = @obj.edit;
            ax.YDir = 'normal';
            xlim(ax,obj.WaveformTime([1 end])*1e3);
            
            xlabel(ax,'time (ms)');
            title(ax,obj.TitleStr);
            
            epa.helper.setfont(ax);

            ax.CLim = [0 quantile(n(:),.95)];
            colormap(ax,flipud(hot));
%             hc = colorbar(ax);
%             hc.YLabel.String = normalization;
%             hc.Visible = 'off';
            
            if nargout == 0, clear h; end
        end
        
        
        
        
    end
end
                
                
