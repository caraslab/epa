classdef Cluster < epa.DataInterface
    % C = epa.Cluster(SessionObj,[ID],[Spiketimes],[SpikeWaveforms])
    
    
    properties
        ID       (1,1) uint64 {mustBeFinite} = 0;
        Type     string
        
        SamplingRate    (1,1) double {mustBePositive,mustBeFinite} = 1; % by default same as obj.Session.SamplingRate
               
        
        Channel         (1,1) double {mustBeFinite,mustBeInteger} = -1;
        Waveforms       (:,:,:) single % [channels x samples x spikes]
        Samples         (:,1) single {mustBeInteger} = [] % single datatype for easier manipulation
        WaveformWindow  (1,2) double {mustBeFinite} = [0 1]
        QualityMetrics  (1,1) struct
        
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
        
        
        function h = gui(obj,src,event)
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
            %i = obj.ShankChannels == obj.Channel;
            [~,i] = max(abs(squeeze(mean(obj.Waveforms(:,17,:),3))));
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
        
        
        
        
        function [ems,y,bins,n,thr,mv] = estimate_missing_spikes(obj)
            % find the sample of the spike minimum
            [~,i] = min(squeeze(obj.Waveforms(obj.channelInd,:,:)),[],1);
            i = mode(i,'all');
            mv = squeeze(obj.Waveforms(obj.channelInd,i,:));
            
            [n,bins] = histcounts(mv,min(mv):5:max(mv));%,'Normalization','pdf');
            bins(1) = [];
            
            
%             mu_hat = bins(find(bins>=mean(mv),1));
            [~,i] = max(n);
            mu_hat = bins(i);
            sigma_hat = std(mv);
            
            y = normpdf(bins,mu_hat,sigma_hat);

            y = y*obj.N*(bins(2)-bins(1)); % pdf -> count
            
            thr = bins(end - find(fliplr(n) > 0,1,'first') + 1);
            ems = obj.N/normcdf(thr,mu_hat,sigma_hat) - obj.N;
            ems = round(ems);
        end
        
        function [coeff,score,latent] = waveform_pca(obj)
            w = reshape(obj.Waveforms,obj.nChannels*obj.nWaveformSamples,obj.nSpikes);
            [coeff,score,latent] = pca(w');
        end
        
        
        function str = quality_metrics_summary(obj)
            
            fn = fieldnames(obj.QualityMetrics);
            ml = max(cellfun(@length,fn));
            str = '';
            for i = 1:length(fn)
                str = sprintf('%s%*s : %s\n',str,ml,fn{i},epa.helper.num2str(obj.QualityMetrics.(fn{i})));
            end
            str(end) = [];
        end
        
        function h = plot_interspike_interval(obj,ax,varargin)
            if nargin < 2 || isempty(ax), ax = gca; end
            if nargin < 3, varargin = {}; end
            
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
            h.rpvthreshold = line(ax,[1 1]*par.rpvthreshold*1e3,ylim(ax),'Color',[.4 .4 .4]);
            hold(ax,'off');
            
            uistack(h.rpvthreshold,'bottom');
            
            grid(ax,'on');
            ax.Title.String = obj.TitleStr;
            ax.YAxis.Label.String = 'count';
            ax.XAxis.Label.String = 'inter-spike interval (ms)';
            ax.XLim = lags([1 end])*1e3;
            

            
            str{1} = sprintf('$n < %g ms = %d$',par.rpvthreshold*1e3,rpvc);

            h.text = text(ax,.95*1e3*lags(end),.95*max(ylim(ax)),str, ...
                'VerticalAlignment','top','HorizontalAlignment','right', ...
                'FontName','Consolas','BackgroundColor',ax.Color, ...
                'Interpreter','latex');

            epa.helper.setfont(ax);

            if nargout == 0, clear h; end
        end
        
        
        function h = plot_waveforms(obj,ax,varargin)
            if nargin < 2 || isempty(ax), ax = gca; end
            
            par.maxwf = inf;
            
            if nargin > 1 && isequal(ax,'getdefaults'), h = par; return; end
            par = epa.helper.parse_params(par,varargin{:});
            
            if obj.nWaveformSamples == 0
                cla(ax);
                title(ax,[obj.TitleStr '- NO SPIKE WAVEFORMS'])
                return
            end
            
            maxwf = min(obj.nSpikes,par.maxwf);
            
            idx = randperm(obj.nSpikes,maxwf);
            idx = sort(idx);
            
            w = squeeze(obj.Waveforms(obj.channelInd,:,idx));

            tvec = 1e3*obj.WaveformTime;
            h = line(ax,tvec,w,'Color',[.4 .4 .4 .2]);
            for i = 1:length(idx)
                h(i).UserData = obj.Samples(idx(i));
            end
            
            xlim(ax,tvec([1 end]));
            
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
        
        
        function h = plot_waveform_density(obj,ax,varargin)
            if nargin < 2 || isempty(ax), ax = gca; end            
            
            
            par.normalization = 'count';
            par.interpn = 2;
            
            if nargin > 1 && isequal(ax,'getdefaults'), h = par; return; end
            par = epa.helper.parse_params(par,varargin{:});
            
            
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
            
            [n,xe,ye] = histcounts2(x,y(:),xb,yb,'Normalization',par.normalization);
            
            if par.interpn > 1
                n = interp2(n,par.interpn);
            end
            h = imagesc(ax,xe,ye,n');

            ax.YDir = 'normal';
            xlim(ax,obj.WaveformTime([1 end])*1e3);
            
            xlabel(ax,'time (ms)');
            title(ax,obj.TitleStr);
            
            epa.helper.setfont(ax);

            colormap(ax,flipud(hot));
            
            
            if nargout == 0, clear h; end
        end
        
        function h = plot_waveform_amplitudes(obj,ax)
            if nargin < 2 || isempty(ax), ax = gca; end
            
            cla(ax,'reset');

            minv = squeeze(min(obj.Waveforms,[],2));
            maxv = squeeze(max(obj.Waveforms,[],2));
            
            minv = minv(obj.channelInd,:);
            maxv = maxv(obj.channelInd,:);
            
            h = line(ax,[1; 1]*obj.SpikeTimes',[minv; maxv], ...
                'LineStyle','none','Marker','.','Color','k');
            for i = 1:obj.N
                h(i).UserData = obj.Samples(i);
            end
            
            xlim(ax,[min(obj.SpikeTimes) max(obj.SpikeTimes)]);
            
            grid(ax,'on');
            box(ax,'on');
            
            ylabel(ax,'amplitude');
            xlabel(ax,'time (s)');
            
            title(ax,obj.TitleStr);
            
            epa.helper.setfont(ax);
            
            if nargout == 0, clear h; end
        end
        
        function h = plot_firingrates(obj,ax,varargin)
            if nargin < 2 || isempty(ax), ax = gca; end
            
            par.binsize = 1;
            par.convbins = 10;
            
            if nargin > 1 && isequal(ax,'getdefaults'), y = par; return; end
            
            par = epa.helper.parse_params(par,varargin{:});
           
            cla(ax,'reset');
            
            [y,bins] = histcounts(obj.SpikeTimes,min(obj.SpikeTimes):par.binsize:max(obj.SpikeTimes), ...
                'Normalization','countdensity');
            bins(end) = [];

            my = max(y);
            y = conv(y,gausswin(par.convbins),'same');
            y = y./max(y)*my;
            
            h = plot(ax,bins,y,'-k');
            
            grid(ax,'on');
            ylabel(ax,'firing rate (Hz)');
            xlabel(ax,'time (s)');
            axis(ax,'tight');
            title(ax,obj.TitleStr);
            
            epa.helper.setfont(ax);
            
            if nargout == 0, clear h; end
        end
        
        function h = plot_missing_spikes_estimate(obj,ax)
            if nargin < 2 || isempty(ax), ax = gca; end

            cla(ax,'reset');
            
            
            [ems,y,bins,n,thr] = obj.estimate_missing_spikes;
            
            h.hist = bar(ax,bins,n,'FaceColor','k','barwidth',1,'edgecolor','none');
            hold(ax,'on')
            h.fit = plot(ax,bins,y,'-r','linewidth',2);
            h.threshold = plot(ax,[thr thr],ylim(ax),'-','color',[.4 .4 .4]);
            hold(ax,'off')
            
            xlabel(ax,'amplitude')
            ylabel(ax,'number of spikes')
           
            grid(ax,'on')
            title(ax,obj.TitleStr)
            
            
            str = sprintf('$\\hat{missing}$ = %d',ems);
            h.text = text(ax,double(bins(1)),.95*max(n),str, ...
                'VerticalAlignment','top', ...
                'HorizontalAlignment','left', ...
                'BackgroundColor',ax.Color, ...
                'Interpreter','latex');

            epa.helper.setfont(ax);

            if nargout == 0, clear h; end
        end
        
    end
end
                
                
