classdef (Hidden) Electrode < handle & matlab.mixin.Heterogeneous

    
    properties
        ID          (1,1) string
        Location    (1,1) string
        ChannelMap  (:,1) double {mustBeInteger,mustBeFinite}
        Marker      (1,1) char   {mustBeMember(Marker,{'.','o','s','d','h'})} = 'o';
        MaxNeighborDist  (1,1) {mustBeNonnegative}
        ChannelImpedance (:,1) double
        
        Name
    end
    
    properties (SetAccess = protected)
        Group           (:,1) double {mustBeInteger,mustBeNonnegative}
        Coordinates     (:,2) double {mustBeFinite}
        Labels          (:,1) string
        ChannelMeasurements   double {mustBePositive} % diameter if one value per channel; width, height if two values per channel
        Units           (1,1) string = "mm";
        Style           (1,1) string {mustBeMember(Style,["acute","chronic","ecog","eeg"])} = "acute"
        Manufacturer    (1,1) string
        Model           (1,1) string
        Neighbours      (:,1) cell
    end
    
    properties (SetAccess = immutable,Abstract)
        N % number of channels
    end
    
    
    methods
        
        function n = get.Name(obj)
            if isempty(obj.Name)
                obj.Name = sprintf('%s %s - %s',obj.Manufacturer,obj.Model,obj.Style);
            end
            n = obj.Name;
        end
        
        function m = get.ChannelMap(obj)
            if isempty(obj.ChannelMap)
                obj.ChannelMap = 1:obj.N;
            end
            m = obj.ChannelMap;
        end
        
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
            
            ug = unique(obj.Group);
            cm = jet(length(ug));
            
            for i = 1:length(ug)
                ind = obj.Group == ug(i);
                h(i) = line(ax,x(ind),y(ind), ...
                    'color','k', ...
                    'linestyle','none', ...
                    'marker',obj.Marker, ...
                    'markerfacecolor',cm(i,:));
            end
            
            axis(ax,'image')
            axis(ax,'off')
            
            title(ax,obj.Name);
            
            if nargout == 0, clear h; end
        end
        
        
    end
    
end