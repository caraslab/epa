classdef Raster < epa.plot.PlotType
    
    
    properties (SetObservable, AbortSet)        
        event           % event name
        eventvalue     (1,:)
        
        window         (1,2) double {mustBeFinite} = [0 1];
        
        showeventonset (1,1) logical = true;
        
        sortevents     (1,:) char {mustBeMember(sortevents,{'original','events'})} = 'original';
        
    end
    
    
    properties (Constant)
        DataFormat = '1D';
        Style = 'Raster';
    end
    
    methods
        function obj = Raster(Cluster,varargin)
            obj = obj@epa.plot.PlotType(varargin{:});
            if nargin > 0 && ~isempty(Cluster)
                obj.Cluster = Cluster;
            end
        end
        
        function set.window(obj,w)
            if numel(w) == 1, w = sortevents([0 w]); end
            obj.window = w(:)';
        end
        
        function plot(obj,src,event)
            % not yet instantiated by calling obj.plot
            if nargin > 1 && isempty(obj.handles), return; end 
            
            obj.setup_plot;
            
            axe = obj.ax;
            cla(axe,'reset');

            
            S = obj.Cluster.Session;
            C = obj.Cluster;
            

            if ~isa(obj.event,'epa.Event')
                obj.event = S.find_Event(obj.event);
            end
            E = obj.event;

            par = epa.helper.obj2par(obj);
            
            [t,eidx,v] = C.eventlocked(par);
            
            
            if isempty(eidx)
                fprintf(2,'No data found for event "%s" in cluster "%s"\n',E.Name,obj.Name)
                return
            end
            
            uv = unique(v);
            
            
            cm = epa.helper.colormap(par.colormap,numel(uv));
            
            % TODO: OPTION TO SHADE BEHIND SPIKES BASED ON EVENT
            
            if par.showeventonset
                par.handles.eventonset = line(axe,[0 0],[0 max(eidx)+1],'color',[0.6 0.6 0.6],'linewidth',1,'tag','ZeroMarker');
            end
            
            if isfield(obj.handles,'raster'), obj.handles = rmfield(obj.handles,'raster'); end
            for i = 1:length(uv)
                ind = uv(i) == v;
                obj.handles.raster(i) = line(axe,t(ind),eidx(ind),'color',cm(i,:), ...
                    'linestyle','none','marker','.', ...
                    'markersize',2,'markerfacecolor',cm(i,:), ...
                    'DisplayName',sprintf('%g%s',uv(i),E.Units), ...
                    'Tag',sprintf('%s_%s = %g%s',C.TitleStr,E.Name,uv(i),E.Units));
            end
            
            
            axe.XLim = par.window;
            axe.YLim = [min(eidx)-1 max(eidx)+1];
            
            axe.XAxis.TickDirection = 'out';
            axe.YAxis.TickDirection = 'out';
            
            if par.showlegend
                legend([par.handles.raster],'location','EastOutside');
            end
            
            switch lower(par.sortevents)
                case 'original'
                    ylabel(axe,'trial');
                case 'events'
                    ylabel(axe,'by event');
            end
            
            
            xlabel(axe,'time (s)');
                        
            % uncertain why, but this needs to be at the end to work properly
            drawnow
            set([obj.handles.raster.MarkerHandle],'Style','vbar');
            

            obj.standard_plot_postamble;
            
        end 
    end % methods (Access = public)
  
    
end