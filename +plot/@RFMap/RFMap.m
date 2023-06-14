classdef RFMap < epa.plot.PlotType
    
    
    properties (SetObservable, AbortSet)        
        eventx          % event name
        eventy
        eventxvalue    (1,:)
        eventyvalue    (1,:)
        
        window         (1,2) double {mustBeFinite} = [0 .1];
                
        onsettolerance (1,1) double {mustBePositive,mustBeNonempty} = 1e-6;
        
        smoothdata     (1,1) double {mustBeNonnegative,mustBeFinite} = 3;
        
    end
    
    properties (Constant)
        DataFormat = '2D';
        Style = 'RFMap';
    end
    
    methods
        function obj = RFMap(Cluster,varargin)
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
            if nargin > 1 && isempty(obj.handles), return; end % not yet instantiated by calling obj.plot

            
            obj.setup_plot;
            
            axe = obj.ax;
            cla(axe,'reset');
            
            C = obj.Cluster;
            S = C.Session;
            
                       
                        
            if ~isa(obj.eventx,'epa.Event')
                obj.eventx = S.find_Event(obj.eventx);
            end
            
                        
            if ~isa(obj.eventy,'epa.Event')
                obj.eventy = S.find_Event(obj.eventy);
            end
            
            Ex = obj.eventx;
            Ey = obj.eventy;            
            
            
            [vx,ootx] = Ex.subset(obj.eventxvalue);
            [vy,ooty] = Ey.subset(obj.eventyvalue);
            
            doot = ootx - ooty;
            ind = doot>obj.onsettolerance;
            ootx(ind) = [];
            vx(ind) = [];
            vy(ind) = [];
            
            Fs = C.SamplingRate;
            ons = round(Fs.*ootx(:,1));

            wins = round(Fs.*obj.window);
            
            
            uvx = unique(vx);
            uvy = unique(vy);
            
            ss = C.Samples;
            
            data = zeros(length(uvy),length(uvx));
            for ix = 1:length(uvx)
                for iy = 1:length(uvy)
                    ind = uvx(ix) == vx & uvy(iy) == vy;
                    idx = find(ind);
                    for k = 1:length(idx)
                        s = sum(ss >= ons(idx(k))+wins(1) & ss <=(ons(idx(k))+wins(2)));
                        data(iy,ix) = data(iy,ix) + s;
                    end
                end
            end
            
            if obj.smoothdata > 0
                [m,n] = size(data);
                
                x = uvx;
                if max(diff(x)) == min(diff(x))
                    xi = linspace(x(1),x(end),n*obj.smoothdata);
                else
                    xi = logspace(log10(x(1)),log10(x(end)),n*obj.smoothdata);
                end
                
                y = uvy;
                if max(diff(y)) == min(diff(y))
                    yi = linspace(y(1),y(end),m*obj.smoothdata);
                else
                    yi = logspace(log10(y(1)),log10(y(end)),m*obj.smoothdata);
                end
               
                [x,y]   = meshgrid(x,y);
                [xi,yi] = meshgrid(xi,yi);
                data = interp2(x,y,data,xi,yi,'makima');
            end
            
            
            obj.handles.rf = imagesc(axe,uvx,uvy,data);
            axe.YDir = 'normal';
            
            cm = epa.helper.colormap(obj.colormap,128);
            colormap(axe,cm); 
            
            
            xlabel(axe,Ex.Name);
            ylabel(axe,Ey.Name);
            

            obj.standard_plot_postamble;
            
            
        end
    end
end