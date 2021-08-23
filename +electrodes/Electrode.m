classdef Electrode < handle & matlab.mixin.Heterogeneous

    
    properties
        ID          (1,1) string
        Location    (1,1) string
        ChannelMap  (:,1) double {mustBeInteger,mustBeFinite}
        Marker      (1,1) char   {mustBeMember(Marker,{'.','o','s','d','h'})} = 'o';
        MaxNeighborDist (1,1) {mustBeNonnegative}
    end
    
    properties (SetAccess = protected)
        Shank           (:,1) double {mustBeInteger,mustBeNonnegative}
        Coordinates     (:,2) double {mustBeFinite}
        Labels          (:,1) string
        ChannelMeasurements   double {mustBePositive} % diameter if one value per channel; width, height if two values per channel
        Units           (1,1) string = "mm";
        Style           (1,1) string {mustBeMember(Style,["acute","chronic","ecog","eeg"])} = "acute"
        Manufacturer    (1,1) string
        Model           (1,1) string
        Neighbours      (:,1) cell
    end
    
    properties (Constant,Abstract)
        N
    end
    
    
    methods
        
        
        function lay = ft_layout(obj)
            lay.pos = obj.Coordinates;
            lay.label = obj.Labels;
            lay.width = obj.ChannelMeasurements(1);
            switch size(obj.ChannelMeasurements,2)
                case 1
                    lay.height = obj.ChannelMeasurements(1);
                case 2
                    lay.height = obj.ChannelMeasurements(2);
            end
        end
        
        
        function set_neighbors(obj)
            x = obj.Coordinates(:,1);
            y = obj.Coordinates(:,2);
            for i = 1:obj.N
                dx = x - x(i);
                dy = y - y(i);
                a = sqrt(dx.^2+dy.^2);
                ind = a > 0 & a <= obj.MaxNeighborDist;
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
                'markerfacecolor',[.6 .6 .6]);
            
            
            axis(ax,'image')
            axis(ax,'off')
            if nargout == 0, clear h; end
        end
        
        
    end
    
end