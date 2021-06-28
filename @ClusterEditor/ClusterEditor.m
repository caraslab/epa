classdef ClusterEditor < handle
    
    properties (SetObservable,AbortSet)
        Cluster
        unselectedColor     (1,3) double {mustBeNonnegative,mustBeLessThanOrEqual(unselectedColor,1)} = [0.5 0.5 0.5];
        unselectedLineWidth (1,1) double {mustBePositive,mustBeFinite} = 1;
        unselectedMarkerSize (1,1) double {mustBePositive,mustBeFinite} = 1;
        selectedColor       (1,3) double {mustBeNonnegative,mustBeLessThanOrEqual(selectedColor,1)} = [1 0 0];
        selectedLineWidth   (1,1) double {mustBePositive,mustBeFinite} = 2;
        selectedMarkerSize  (1,1) double {mustBePositive,mustBeFinite} = 10;
        
        selectedSamples     (:,1) single {mustBePositive,mustBeFinite}
    end
    
    properties (SetAccess = private, GetAccess = protected)
        maintiles
        ax_waveforms
        ax_density
        ax_pca
        ax_isi
        
        h_waveforms
        h_meanwaveform
        h_pca
        h_density
        h_isi
        
        roi
    end
    
    properties (SetAccess = immutable)
        parent
        figure
    end
    
    methods
        function obj = ClusterEditor(ClusterObj,parent)
            
            obj.Cluster = ClusterObj;
            
            if nargin < 2 || isempty(parent)
                parent = figure('Color','w','Position',[150 150 900 500]);
            end
            obj.parent = parent;
            obj.figure = ancestor(obj.parent,'figure');
            
            obj.create;
            
            addlistener(obj,'selectedSamples','PostSet',@obj.update_selection);
            
            movegui(obj.figure);
        end
        
        function update_selection(obj,src,event)
            ind = ismember(obj.Cluster.Samples,obj.selectedSamples);
            
            set(obj.h_waveforms(ind), ...
                'LineWidth',obj.selectedLineWidth, ...
                'Color',obj.selectedColor);
            
            set(obj.h_waveforms(~ind), ...
                'LineWidth',obj.unselectedLineWidth, ...
                'Color',obj.unselectedColor);
            
            set(obj.h_pca(ind), ...
                'MarkerSize',obj.selectedMarkerSize, ...
                'Color',obj.selectedColor);
            
            set(obj.h_pca(~ind), ...
                'MarkerSize',obj.unselectedMarkerSize, ...
                'Color',obj.unselectedColor);
            
            drawnow limitrate
            
            uistack([obj.h_meanwaveform, obj.h_waveforms(ind)],'top');
            
        end
        
    end
    
    methods (Access = protected)
        
        
        function select_spike(obj,src,event)
            if nargin == 1, return; end
            
            sample = src.UserData;
            
            ind = obj.selectedSamples == sample;
            
            if any(ind)
                obj.selectedSamples(ind) = [];
            else
                obj.selectedSamples(end+1) = sample;
            end
            
        end
        
        function remove_spikes(obj)
            
            obj.Cluster.rem_spikes(obj.selectedSamples);
            
            s = cell2mat(get(obj.h_waveforms,'UserData'));
            ind = ismember(obj.Cluster.Samples,s);
            obj.h_waveforms(ind) = [];
            
            
            s = cell2mat(get(obj.h_pca,'UserData'));
            ind = ismember(obj.Cluster.Samples,s);
            obj.h_pca(ind) = [];
            
            obj.selectedSamples = [];
        end
        
        function plot_density(obj)
            obj.h_density = obj.Cluster.plot_waveform_density(obj.ax_density);
            ylim(obj.ax_density,ylim(obj.ax_waveforms));
        end
        
        function plot_waveforms(obj)
            ax = obj.ax_waveforms;
            obj.h_waveforms = obj.Cluster.plot_waveforms(ax,inf);
            for i = 1:length(obj.h_waveforms)
                obj.h_waveforms(i).UserData = obj.Cluster.Samples(i);
            end
            hold(ax,'on');
            obj.h_meanwaveform = obj.Cluster.plot_waveform_mean(ax);
            hold(ax,'off');
            set([obj.h_waveforms(:); obj.h_meanwaveform(:)],'ButtonDownFcn',@obj.select_spike);
            
            set(obj.h_waveforms,'ButtonDownFcn',@obj.select_spike);
        end
        
        function plot_pca(obj)
            ax = obj.ax_pca;
            [~,scores,~] = obj.Cluster.waveform_pca;
            smp = obj.Cluster.Samples;
            for i = 1:size(scores,1)
                obj.h_pca(i) = line(ax,scores(i,1),scores(i,2),scores(i,3), ...
                    'LineStyle','none','Marker','.','MarkerSize',1, ...
                    'color','k','UserData',smp(i));
            end
            grid(ax,'on');
            xlabel(ax,'PC1');
            ylabel(ax,'PC2');
            zlabel(ax,'PC3');
            axis(ax,'tight');
            set(ax,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[]);
            view(ax,3);
            set(obj.h_pca,'ButtonDownFcn',@obj.select_spike);
        end
        
        function plot_isi(obj)
            
        end
        
        
        
        
    end
    
    
    methods (Access = private)
        function create(obj)
            t = tiledlayout(2,2,'Tag','MainTiles');
            obj.maintiles = t;
            
            
            % density
            obj.ax_density = nexttile(t);
            
            
            % waveforms
            obj.ax_waveforms = nexttile(t);
            
            
            % isi
            %ax = nexttile(t);
            %obj.ax_isi = ax;
            
            
            % pca
            obj.ax_pca = nexttile(t);
            
            obj.plot_waveforms;
            obj.plot_density;
            obj.plot_pca;
            
            
            obj.figure.WindowKeyPressFcn = @obj.key_processor;


%             obj.els = addlistener(
        end
        
        
        function key_processor(obj,src,event)
            
            switch event.Character
                case '?'
                    
                case 'c'
                    obj.selectedSamples = [];
                    
                case 'r'
                    if isempty(obj.selectedSamples), return; end
                    str = sprintf('Remove %d of %d spikes?', ...
                        length(obj.selectedSamples),obj.Cluster.N);
                    b = questdlg(str,'Remove Samples','Remove','Cancel','Cancel');
                    if isequal(b,'Remove')
                        obj.remove_spikes;
                    end
            end
        end
    end
end
