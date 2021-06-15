classdef PSTH < epa.plot.PlotType
    
    
    properties (SetObservable, AbortSet)
        event           % event name
        eventvalue     (1,:)
        
        binsize        (1,1) double {mustBeNonempty,mustBePositive,mustBeFinite} = 0.01;
        window         (1,2) double {mustBeNonempty,mustBeFinite} = [0 1];
        normalization  (1,:) char {mustBeNonempty,mustBeMember(normalization,{'count','firingrate','countdensity','probability','cumcount','cdf','pdf'})} = 'firingrate';
        showeventonset (1,1) logical {mustBeNonempty} = true;        
    end
    
    
    properties (Constant)
        DataFormat = '1D';
        Style = 'PSTH';
    end
    
    methods
        function obj = PSTH(Cluster,varargin)
            obj = obj@epa.plot.PlotType(varargin{:});
            if nargin > 0 && ~isempty(Cluster)
                obj.Cluster = Cluster;
            end
        end
        
        function set.window(obj,w)
            if numel(w) == 1, w = sort([0 w]); end
            obj.window = w(:)';
        end
        
        
        function plot(obj,src,event)
            if nargin > 1 && isempty(obj.handles), return; end % not yet instantiated by calling obj.plot

            obj.setup_plot;
            
            axe = obj.ax;
            cla(axe,'reset');
            
            C = obj.Cluster;
            S = C.Session;
            
            cla(axe,'reset');
            
            
            if ~isa(obj.event,'epa.Event')
                obj.event = S.find_Event(obj.event);
            end
            
            E = obj.event;
            
            
            [c,b,uv] = C.psth(obj);
            
%             cm = epa.helper.colormap(obj.colormap,size(c,1));
            
            cla(axe,'reset');
            
            if obj.showeventonset
                obj.handles.eventonset = line(axe,[0 0],[0 max(c(:))*1.1],'color',[0.6 0.6 0.6],'linewidth',1,'tag','ZeroMarker');
            end
            
            b = [b; b+obj.binsize];
            b = b(:)';
            
            b = [b b(end) b(1)];
            
            mc = max(c(:));
            for i = 1:length(uv)
                x = c(i,:);
                x = [x; x];
                x = x(:)';
                x = [x 0 0];
                obj.handles.plot(i) = patch(axe,b,(i-1)*mc+x,[0 0 0]);
            end
            
            xlabel(axe,'time (s)');
            
            switch lower(obj.normalization)
                case {'firingrate','fr'}
                    ylabel(axe,'firing rate (Hz)');
                otherwise
                    ylabel(axe,obj.normalization);
            end
            
            
            
            axe.XLim = obj.window;
            
            axe.XAxis.TickDirection = 'out';
            axe.YAxis.TickDirection = 'out';
            
            axis(axe,'tight');

            obj.standard_plot_postamble;
            
        end
        
        
    end
    
end