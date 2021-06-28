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
        
        roi_waveform
        roi_pca
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
            
            obj.figure.Pointer = 'watch'; drawnow
            ind = ismember(obj.Cluster.Samples,obj.selectedSamples);
            
            if any(ind)
                set(obj.h_waveforms(ind), ...
                    'LineWidth',obj.selectedLineWidth, ...
                    'Color',obj.selectedColor);
                
                set(obj.h_pca(ind), ...
                    'MarkerSize',obj.selectedMarkerSize, ...
                    'Color',obj.selectedColor);
            end
            
            set(obj.h_waveforms(~ind), ...
                'LineWidth',obj.unselectedLineWidth, ...
                'Color',obj.unselectedColor);
            
            set(obj.h_pca(~ind), ...
                'MarkerSize',obj.unselectedMarkerSize, ...
                'Color',obj.unselectedColor);
            
            drawnow limitrate
            
            obj.figure.Pointer = 'arrow';
            
            uistack([obj.h_meanwaveform, obj.h_waveforms(ind)],'top');
            
        end
        
        function invert_selection(obj)
            obj.selectedSamples = setdiff(obj.Cluster.Samples,obj.selectedSamples);
        end
        
    end % methods (Access = public)
    
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
            ind = ismember(s,obj.Cluster.Samples);
            delete(obj.h_waveforms(~ind))
            obj.h_waveforms(~ind) = [];
            
            s = cell2mat(get(obj.h_pca,'UserData'));
            ind = ismember(s,obj.Cluster.Samples);
            delete(obj.h_pca(~ind));
            obj.h_pca(~ind) = [];
            
            obj.selectedSamples = [];
            
            obj.plot_isi;
            
            delete(obj.h_meanwaveform);
            hold(obj.ax_waveforms,'on');
            obj.h_meanwaveform = obj.Cluster.plot_waveform_mean(obj.ax_waveforms);
            hold(obj.ax_waveforms,'off');
            
            obj.plot_density;
        end
        
        function plot_density(obj)
            obj.h_density = obj.Cluster.plot_waveform_density(obj.ax_density);
            ylim(obj.ax_density,ylim(obj.ax_waveforms));
        end
        
        function plot_waveforms(obj)
            ax = obj.ax_waveforms;
            obj.h_waveforms = obj.Cluster.plot_waveforms(ax,inf);
            hold(ax,'on');
            obj.h_meanwaveform = obj.Cluster.plot_waveform_mean(ax);
            hold(ax,'off');
            set(obj.h_waveforms,'ButtonDownFcn',@obj.select_spike);
        end
        
        function plot_pca(obj)
            ax = obj.ax_pca;
            [~,scores,~] = obj.Cluster.waveform_pca;
            smp = obj.Cluster.Samples;
            for i = 1:size(scores,1)
                obj.h_pca(i) = line(ax,scores(i,1),scores(i,2),scores(i,3), ...
                    'LineStyle','none','Marker','.','MarkerSize',obj.unselectedMarkerSize, ...
                    'color',obj.unselectedColor,'UserData',smp(i));
            end
            grid(ax,'on');
            box(ax,'on');
            xlabel(ax,'PC1');
            ylabel(ax,'PC2');
            zlabel(ax,'PC3');
            axis(ax,'tight');
            set(ax,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[]);
            view(ax,3);
            
            set(obj.h_pca,'ButtonDownFcn',@obj.select_spike);
        end
        
        function plot_isi(obj)
            obj.h_isi = obj.Cluster.plot_interspike_interval(obj.ax_isi);
            obj.h_isi.rpv.FaceColor = 'm';
            box(obj.ax_isi,'on');
        end
        
        
        function create_roi(obj,type)
            
            switch lower(type)
                case 'waveform'                    
                    ax = obj.ax_waveforms;
                    roifnc = @drawrectangle;
                case 'pca'
                    ax = obj.ax_pca;
                    roifnc = @drawcuboid;
            end
            
            
            roi = roifnc(ax,'LineWidth',0.5,'UserData',obj, ...
                'FaceAlpha',0.1,'LabelVisible','hover', ...
                'LineWidth',0.5,'UserData',type);
            
            addlistener(roi,'MovingROI',@obj.update_roi);
            addlistener(roi,'ROIMoved',@obj.update_roi);
            addlistener(roi,'DrawingStarted',@obj.update_roi);
            addlistener(roi,'DrawingFinished',@obj.update_roi);

            
            switch lower(type)
                case 'waveform'
                    roi.Rotatable = true;
                    obj.roi_waveform(end+1) = roi;
                case 'pca'
                    obj.roi_pca(end+1) = roi;
            end

            obj.update_roi(roi);
        end
        
        function update_roi(obj,roi,event)
            switch roi.UserData
                case 'waveform'
                    h = obj.h_waveforms;
                case 'pca'
                    h = obj.h_pca;
            end
            ind = obj.get_roi_samples(roi);
            
            h = handle(h);
            obj.selectedSamples = [h(ind).UserData];
            
            roi.Label = sprintf('%d of %d',length(obj.selectedSamples),length(ind));
            
            drawnow limitrate
        end
        
        
        function ind = get_roi_samples(obj,roi)
            switch roi.UserData
                case 'waveform'
                    h = obj.h_waveforms;
                    
                    x = double(cell2mat(get(h,'XData')));
                    y = double(cell2mat(get(h,'YData')));
                    
                    ind = true(size(x,1),1);
                    for k = 1:length(obj.roi_waveform)
                        k_ind = false(size(ind));
                        k_roi = handle(obj.roi_waveform(k));
                        for i = 1:size(x,2)
                            k_ind = k_ind | inROI(k_roi,x(:,i),y(:,i));
                        end
                        ind = ind & k_ind;
                    end
                    
                case 'pca'
                    h = obj.h_pca;
                    
                    x = double(cell2mat(get(h,'XData')));
                    y = double(cell2mat(get(h,'YData')));
                    z = double(cell2mat(get(h,'ZData')));
                    
                    ind = inROI(roi,x,y,z);
            end
        end
        
    end % methods (Access = protected)
    
    
    methods (Access = private)
        function create(obj)
            t = tiledlayout(2,2,'Tag','MainTiles');
            obj.maintiles = t;
            
            
            % density
            obj.ax_density = nexttile(t);
            
            
            % waveforms
            obj.ax_waveforms = nexttile(t);
            
            
            % isi
            obj.ax_isi = nexttile(t);
            
            
            % pca
            obj.ax_pca = nexttile(t);
            
            obj.plot_waveforms;
            obj.plot_density;
            obj.plot_pca;
            obj.plot_isi;
            
            obj.update_selection;
            
            obj.figure.WindowKeyPressFcn = @obj.key_processor;
            
        end
        
        
        
        function key_processor(obj,src,event)
            
            switch event.Character
                case {'/','?'}
                    fprintf('\n')
                    disp('Cluster Editor key bindings:')
                    disp('''c'' - clear currently selected spikes')
                    disp('''d'' - delete currently selected spikes')
                    disp('''i'' - invert current selection')
                    disp('''p'' - use an region of interest selection method on the PCA scatter plot')
                    disp('''w'' - add a box threshold to select waveforms')
                    

                case 'w'
                    obj.create_roi('waveform');

                case 'c'
                    obj.selectedSamples = [];
                    delete(obj.roi_pca); obj.roi_pca = [];
                    delete(obj.roi_waveform); obj.roi_waveform = [];
                    
                case 'd'
                    if isempty(obj.selectedSamples), return; end
                    str = sprintf('Delete %d of %d spikes?', ...
                        length(obj.selectedSamples),obj.Cluster.N);
                    b = questdlg(str,'Delete Spikes','Delete','Cancel','Cancel');
                    if isequal(b,'Delete')
                        obj.remove_spikes;
                    end
                    obj.selectedSamples = [];
                    delete(obj.roi_pca); obj.roi_pca = [];
                    delete(obj.roi_waveform); obj.roi_waveform = [];
                    
                case 'i'
                    obj.invert_selection;
                    delete(obj.roi_pca); obj.roi_pca = [];
                    delete(obj.roi_waveform); obj.roi_waveform = [];
                    
                case 'p'
                    obj.create_roi('pca');
            end
        end
        
    end % methods (Access = private)
end
