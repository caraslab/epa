classdef Electrode < handle
    
    properties
        ID          (1,1) string
        Location    (1,1) string
        ChannelMap  (:,1) double {mustBeInteger,mustBeFinite}
        Marker      (1,1) char   {mustBeMember(Marker,{'.','o','s','d','h'})} = 'o';
    end
    
    
    properties (SetAccess = protected)
        Shank           (:,1) double {mustBeInteger,mustBeNonnegative}
        Coordinates     (:,2) double {mustBeFinite}
        Labels          (:,1) string
        Diameter        (:,1) double {mustBePositive}
        Width           (:,1) double {mustBePositive}
        Height          (:,1) double {mustBePositive}
        Units           (1,1) string = "mm";
        Style           (1,1) string {mustBeMember(Style,["acute","chronic","ecog","eeg"])} = "acute"
        Manufacturer    (1,1) string
        Model           (1,1) string
        Neighbours      (:,1) cell
    end
    
    properties (Dependent)
        N
    end
    
    
    methods
        
        function lay = ft_layout(obj)
            lay.pos = obj.Coordinates;
            lay.label = obj.Labels;
            lay.width = obj.Diameter;
            lay.height = obj.Diameter;
        end
        
        function n = get.N(obj)
            n = size(obj.Coordinates,1);
        end
        
        function set_neighbours(obj,maxdist)
            x = obj.Coordinates(:,1);
            y = obj.Coordinates(:,2);
            for i = 1:obj.N
                dx = x - x(i);
                dy = y - y(i);
                a = sqrt(dx.^2+dy.^2);
                ind = a > 0 & a <= maxdist;
                obj.Neighbours{i} = find(ind);
            end
        end
        
        function h = plot(obj,ax)
            if nargin < 2 || isempty(ax), ax = gca; end
            
            x = obj.Coordinates(:,1);
            y = obj.Coordinates(:,2);
            h = plot(ax,x,y, ...
                'k','linestyle','none', ...
                'marker',obj.Marker, ...
                'markerfacecolor',[.4 .4 .4]);
%             xlim(ax,[min(x) max(x)]+[0.9 1.1]);
%             ylim(ax,[min(y) max(y)].*[0.9 1.1]);
            
            if nargout == 0, clear h; end
        end
        
    end
end