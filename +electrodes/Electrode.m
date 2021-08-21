classdef Electrode < handle
    
    properties
        ID      (1,1) string
    end
    
    
    properties (SetAccess = protected)
        coordinates     (:,2) double
        labels          (:,1) string
        diameter        (:,1) double
        units           (1,1) string = "mm";
        style           (1,1) string {mustBeMember(style,["acute","chronic","ecog","eeg"])} = "acute"
        manufacturer    (1,1) string
        model           (1,1) string
        
        neighbours      (:,1) cell
    end
    
    properties (Dependent)
        N
    end
    
    
    methods
        
        
        function n = get.N(obj)
            n = size(obj.coordinates,1);
        end
        
        function set_neighbours(obj,maxdist)
            x = obj.coordinates(:,1);
            y = obj.coordinates(:,2);
            for i = 1:obj.N
                dx = x - x(i);
                dy = y - y(i);
                a = sqrt(dx.^2+dy.^2);
                ind = a > 0 & a <= maxdist;
                obj.neighbours{i} = find(ind);
            end
        end
        
        function h = plot(obj,ax)
            if nargin < 2 || isempty(ax), ax = gca; end
            
            x = obj.coordinates(:,1);
            y = obj.coordinates(:,2);
            h = plot(ax,x,y, ...
                'ok','markerfacecolor',[.4 .4 .4]);
            
            xlim(ax,[min(x) max(x)]+[0.9 1.1]);
            ylim(ax,[min(y) max(y)].*[0.9 1.1]);
            
            if nargout == 0, clear h; end
        end
        
    end
end