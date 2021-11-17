classdef (Hidden) Electrode < handle & matlab.mixin.Heterogeneous

    
    properties
        ID          (1,1) string
        Location    (1,1) string
        ChannelMap  (:,1) double {mustBeInteger,mustBeFinite}
        Marker      (1,1) char   {mustBeMember(Marker,{'.','o','s','d','h','p'})} = 'o';
        MaxNeighborDist  (1,1) {mustBeNonnegative}
        ChannelImpedance (:,1) double
        
        PhysicalScaleFactor  (1,1) double = 1
        
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
            lay.pos = obj.Coordinates./obj.PhysicalScaleFactor;
            lay.label = cellstr(obj.Labels);
            lay.width = obj.ChannelMeasurements(1);
            switch size(obj.ChannelMeasurements,2)
                case 1
                    lay.height = obj.ChannelMeasurements(1);
                case 2
                    lay.height = obj.ChannelMeasurements(2);
            end
            
            lay.width  = lay.width *ones(obj.N+2,1)./obj.PhysicalScaleFactor;
            lay.height = lay.height*ones(obj.N+2,1)./obj.PhysicalScaleFactor;
            
            % add COMNT and SCALE
            x = lay.pos(:,1);
            y = lay.pos(:,2);
            
            mx = [min(x) max(x)];
            my = [min(y) max(y)];
            
            dy = y-y';
            dy = min(abs(dy(dy~=0)));
            
            lay.pos(end+1,:) = [mx(1) my(1)-dy];
            lay.label{end+1} = 'COMNT';
            lay.pos(end+1,:) = [mx(2) my(1)-dy];
            lay.label{end+1} = 'SCALE';
            
            cfg.layout = lay;
            lay = ft_prepare_layout(cfg);
            lay.outline = {};
        end
        
        function nbr = ft_neighbours(obj)
            for i = 1:length(obj.Neighbours)
                nbr(i).label = obj.Labels{i};
                nbr(i).neighblabel = cellstr(obj.Labels(obj.Neighbours{i}))';
            end
        end
        
        
        function n = set_neighbors(obj)
            for i = 1:obj.N
                a = vecnorm(obj.Coordinates - obj.Coordinates(i,:),2,2);
                ind = a > 0 & a <= obj.MaxNeighborDist;
                obj.Neighbours{i} = find(ind);
            end
            if nargout == 1, n = obj.Neighbours; end
        end
        
        function h = plot(obj,ax,channelColors,showlabels)
            if nargin < 2 || isempty(ax), ax = gca; end
            if nargin < 3, channelColors = []; end
            if nargin < 4 || isempty(showlabels), showlabels = true; end
            
            x = obj.Coordinates(:,1);
            y = obj.Coordinates(:,2);
            
            
            if isempty(channelColors) % by group
                ug = unique(obj.Group);
                cm = jet(length(ug));
                tmpc = nan(obj.N,3);
                for i = 1:length(ug)
                    ind = obj.Group == ug(i);
                    tmpc(ind,:) = repmat(cm(i,:),sum(ind),1);
                end
                channelColors = tmpc;
                
            elseif size(channelColors,1) == 1
                channelColors = repmat(channelColors,obj.N,1);
            end
            
            assert(all(size(channelColors) == [obj.N 3]),'epa:electrodes:Electrode:plot:SizeMismatch', ...
                'the size of channelColors must be [obj.N x 3]');
            
            for i = 1:obj.N
                h(i) = line(ax,x(i),y(i), ...
                    'color','k', ...
                    'linestyle','none', ...
                    'marker',obj.Marker, ...
                    'markerfacecolor',channelColors(i,:));
            end
            title(ax,obj.Name,'interpreter','none');
            axis(ax,'image')
            axis(ax,'off')
            
            if showlabels
                ht = obj.channel_text(ax);
                set(ht,'VerticalAlignment','top');
            end
            
            
            if nargout == 0, clear h; end
        end
        
        function h = channel_text(obj,ax)
            if nargin < 2 || isempty(ax), ax = gca; end
            
            str = [obj.Labels];
            str = str(obj.ChannelMap);
            txt = arrayfun(@num2str,str,'uni',0);
            h = text(ax,obj.Coordinates(:,1),obj.Coordinates(:,2),txt, ...
                'FontName','Consolas', ...
                'HorizontalAlignment','center');
            
            if nargout == 0, clear h; end
        end
        
    end
    
end