classdef PSTH < epa.plot.PlotType
    
    
    properties (SetObservable, AbortSet)
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
            
            
            
                        
            
            [c,b,uv] = C.psth(obj);
            nvals = length(uv);
            % cm = epa.helper.colormap(obj.colormap,size(c,1));
            
            cla(axe,'reset');
            
            b = [b; b+obj.binsize];
            b = b(:)';
            b = [b b(end) b(1)];
            
            mc = max(c(:));
            for i = 1:nvals
                x = [c(i,:); c(i,:)];
                x = [x(:)' 0 0];
                x = (i-1)*mc+x;
                obj.handles.plot(i) = patch(axe,b,x,[0 0 0]);
                
                str = sprintf('%s = %g%s',obj.event.Name,uv(i),obj.event.Units);
                obj.handles.label(i) = text(axe,max(b),i*mc-0.05*mc,str);
            end
            
            set(obj.handles.label,'HorizontalAlignment','right', ...
                'VerticalAlignment','top', ...
                'FontName','Consolas', ...
                'FontSize',8);
            
            if obj.showeventonset
                obj.handles.eventonset = line(axe,[0 0],[0 nvals*mc], ...
                    'color',[0.6 0.6 0.6],'linewidth',1,'tag','ZeroMarker');
            end
            
            xlabel(axe,'time (s)');
            
            switch lower(obj.normalization)
                case {'firingrate','fr'}
                    ylabel(axe,'firing rate (Hz)');
                otherwise
                    ylabel(axe,obj.normalization);
            end
            
            axe.YLim = [0 nvals*mc];
            axe.XLim = obj.window;
            
            axe.XAxis.TickDirection = 'out';
            axe.YAxis.TickDirection = 'out';
            
            tv = []; tvl = [];
            for i = 1:nvals
                y = floor(linspace(0,mc,5));
                tvl = [tvl y];
                tv  = [tv y+(i-1)*mc];
            end
            ind = tvl == 0;
            tv(ind) = []; tvl(ind) = [];
            tv = [0 tv]; tvl = [0 tvl];
            axe.YAxis.TickValues = tv;
            axe.YAxis.TickLabels = tvl;
            
            axe.YAxis.Label.FontSize = 10;
            axe.YAxis.FontSize = 8;
            
            axe.XAxis.Label.String = 'time (s)';
            axe.XAxis.Label.FontSize = 10;
            axe.XAxis.FontSize = 8;
            

            obj.standard_plot_postamble;
            
        end
        
        
    end
    
end