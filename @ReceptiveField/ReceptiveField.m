
classdef ReceptiveField < handle
    
       
    properties (SetObservable = true)
        Cluster     (1,1) %epa.Cluster
        Events
        
        event           % event name
        eventvalue  (1,:)
        
        plotstyle   (1,:) char {mustBeMember(plotstyle,{'surf','imagesc','contourf','contour'})} = 'contour';

        metric      (1,:) char {mustBeMember(metric,{'sum','mean','median','mode'})} = 'mean';
        window      (1,2) double {mustBeNonempty,mustBeFinite} = [0 1];
        
        smoothdata (1,1) double {mustBeNonempty,mustBeNonnegative,mustBeFinite} = 0;
        
        colormap = @parula;
    end
    
    
    properties
        ax
    end
    
    properties (Dependent)
        data
        windowSamples
        
        xValues
        yValues
        
        xEvent
        yEvent
    end
    
    methods
        function obj = ReceptiveField(Cluster,varargin)
            obj.Cluster = Cluster;
            
            par = epa.helper.parse_params(obj,varargin{:});
            
            m = metaclass(obj);
            p = m.PropertyList;
            ind = [p.Dependent];
            p(ind) = [];
            pn = {p.Name};
            fn = fieldnames(par);
            pn = intersect(pn,fn);
            for i = 1:length(pn)
                obj.(pn{i}) = par.(pn{i});
            end
        end
        
        
        
        
        function d = get.xValues(obj)
            d = obj.xEvent.DistinctValues;
            if obj.smoothdata
                n = length(d);
                x = 1:n;
                xi = linspace(1,n,n*obj.smoothdata);
                d = interp1(x,d,xi,'makima');
            end
        end
        
        function d = get.yValues(obj)
            d = obj.yEvent.DistinctValues;
            if obj.smoothdata
                n = length(d);
                x = 1:n;
                xi = linspace(1,n,n*obj.smoothdata);
                d = interp1(x,d,xi,'makima');
            end
        end
        
        function xe = get.xEvent(obj)
            xe = obj.Events(1);
        end
        
        function ye = get.yEvent(obj)
            ye = obj.Events(2);
        end
        
        function s = get.windowSamples(obj)
            s = round(obj.Cluster.SamplingRate.*obj.window);
        end
        
        
        function d = get.data(obj)
            if isempty(obj.Events), return; end
            
            ons = obj.Events(1).OnOffSamples(:,1);
            ons = ons+obj.windowSamples;
            
            ss = obj.Cluster.SpikeSamples;
            sc = zeros(size(ons,1),1);
            for i = 1:size(ons,1)
                ind = ss >= ons(i,1) & ss < ons(i,2);
                sc(i) = sum(ind);
            end
                        
            ev_y = obj.yEvent.Values; uev_y = unique(ev_y);
            ev_x = obj.xEvent.Values; uev_x = unique(ev_x);
            d = zeros(length(uev_y),length(uev_x));
            for i = 1:length(uev_y)
                for j = 1:length(uev_x)
                    ind = ev_y == uev_y(i) & ev_x == uev_x(j);
                    d(i,j) = feval(obj.metric,sc(ind));
                end
            end
            
            if obj.smoothdata
                [m,n] = size(d);
                d = interpft(d,obj.smoothdata*m,1);
                d = interpft(d,obj.smoothdata*n,2);
            end
        end
        
        
        function cm = get.colormap(obj)
            switch class(obj.colormap)
                case 'function_handle'
                    cm = feval(obj.colormap);
                    
                case 'char'
                    cm = feval(obj.colormap);
                    
                otherwise
                    cm = obj.colormap;
            end

        end
        
        
        function h = plot(obj,ax)
            if nargin < 2, ax = gca; end
            obj.ax = ax;
            
            h = obj.(['plot_' obj.plotstyle]);
            
            colormap(ax,obj.colormap); %#ok<CPROPLC>
            
            axis(ax,'tight');

            obj.label_axes;
                        
            if nargout == 0, clear h; end
        end
        
    end
   
    methods (Access = protected)
        
        
        function h = plot_contour(obj,ax)
            if nargin < 2, ax = gca; end            
            [mx,my] = meshgrid(obj.xValues,obj.yValues);
            h = contour(ax,mx,my,obj.data);
        end
        
        
        function h = plot_contourf(obj,ax)
            if nargin < 2, ax = gca; end            
            [mx,my] = meshgrid(obj.xValues,obj.yValues);
            h = contourf(ax,mx,my,obj.data);
        end
        
        function h = plot_surf(obj,ax)
            if nargin < 2, ax = gca; end            
            h = surf(ax,obj.xValues,obj.yValues,obj.data);
        end
        
        function h = plot_imagesc(obj,ax)
            if nargin < 2, ax = gca; end            
            h = imagesc(ax,obj.xValues,obj.yValues,obj.data);
            ax.YDir = 'normal';
        end
        
        function label_axes(obj)
            oax = obj.ax;
            
            oax.XAxis.Label.Interpreter = 'none';
            oax.YAxis.Label.Interpreter = 'none';
            oax.ZAxis.Label.Interpreter = 'none';
            
            oax.XAxis.Label.String = obj.xEvent.Name;
            oax.YAxis.Label.String = obj.yEvent.Name;
            oax.ZAxis.Label.String = obj.metric;
            
            oax.Title.Interpreter = 'none';
            oax.Title.String = obj.Cluster.TitleStr;
            
            epa.helper.setfont(oax);
        end
    end
end