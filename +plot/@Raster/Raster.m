classdef Raster < epa.plot.PlotType
    
    
    properties (SetObservable, AbortSet)
        window         (1,2) double {mustBeFinite} = [0 1];
        
        sortevents     (1,:) char {mustBeMember(sortevents,{'original','events'})} = 'original';
        
        markersize     (1,1) double {mustBePositive,mustBeFinite} = 2;
        markerstyle    (1,:) char {mustBeMember(markerstyle,{'plus','circle','asterisk','point','x','square','diamond','downtriangle','triangle','righttriangle','lefttriangle','pentagram','hexagram','vbar','hbar','none'})} = 'vbar';
        
        showeventonset (1,1) logical = true;
        showeventlabel (1,1) logical = true;    
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

            
            C = obj.Cluster;
            if ~isa(obj.event,'epa.Event')
                obj.event = S.find_Event(obj.event);
            end
            
            par = epa.helper.obj2par(obj);
            
            [t,eidx,v] = C.eventlocked(par);
            
            
            if isempty(eidx)
                fprintf(2,'No data found for event "%s" in cluster "%s"\n',obj.event.Name,C.Name)
                return
            end
            


            uv = unique(v);
            for i = 1:length(uv)
                idx = find(uv(i) == v,1);
                sep(i) = eidx(idx)-1;
                obj.handles.seperator(i) = line(axe,par.window,[1 1].*sep(i),'color',[0.8 0.8 0.8]);
            end
            
            obj.handles.raster = line(axe,t,eidx, ...
                'linestyle','none','color',[0 0 0], ...
                'markersize',obj.markersize,'marker','.');
                
            axe.XLim = par.window;
            axe.YLim = [min(eidx)-1 max(eidx)+1];
            
            axe.XAxis.TickDirection = 'out';
            axe.YAxis.TickDirection = 'out';
            
            tv = [diff(sep)./2 (max(eidx)-sep(end))./2+sep(end)];
            axe.YAxis.TickValues = tv;
            axe.YAxis.TickLabels = num2str(uv);
            
            if isa(par.event,'epa.Event')
                axe.YAxis.Label.String = par.event.Name;
            else
                axe.YAxis.Label.String = par.event;
            end
            axe.YAxis.Label.FontSize = 10;
            axe.YAxis.FontSize = 8;
            
            axe.XAxis.Label.String = 'time (s)';
            axe.XAxis.Label.FontSize = 10;
            axe.XAxis.FontSize = 8;
            
            if par.showlegend
                legend([par.handles.raster],'location','EastOutside');
            end
            
%             switch lower(par.sortevents)
%                 case 'original'
%                     ylabel(axe,'trial');
%                 case 'events'
%                     ylabel(axe,'by event');
%             end
            
                        
            % uncertain why, but this needs to be at the end to work properly
            drawnow
            set([obj.handles.raster.MarkerHandle],'Style',obj.markerstyle);
            

            obj.standard_plot_postamble;
            
        end 
    end % methods (Access = public)
  
    
end