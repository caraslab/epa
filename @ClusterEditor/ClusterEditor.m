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
        ax_amplitude
        ax_missing
        ax_firingrate
        
        h_waveforms
        h_meanwaveform
        h_pca
        h_density
        h_isi
        h_amplitude
        h_missing
        h_firingrate
        
        roi_waveform
        roi_amplitude
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
            tstr{1} = sprintf('%s - %d spikes',obj.Cluster.Name,obj.Cluster.N);
            tstr{2} = 'updating ...';
            sgtitle(obj.maintiles,tstr);
            obj.figure.Pointer = 'watch'; drawnow
            ind = ismember(obj.Cluster.Samples,obj.selectedSamples);
            
            if any(ind)
                set(obj.h_waveforms(ind), ...
                    'LineWidth',obj.selectedLineWidth, ...
                    'Color',obj.selectedColor);
                
                set(obj.h_pca(ind), ...
                    'MarkerSize',obj.selectedMarkerSize, ...
                    'Color',obj.selectedColor);
                
                set(obj.h_amplitude(ind), ...
                    'MarkerSize',obj.selectedMarkerSize, ...
                    'Color',obj.selectedColor);
            end
            
            set(obj.h_waveforms(~ind), ...
                'LineWidth',obj.unselectedLineWidth, ...
                'Color',obj.unselectedColor);
            
            set(obj.h_pca(~ind), ...
                'MarkerSize',obj.unselectedMarkerSize, ...
                'Color',obj.unselectedColor);
            
            
            set(obj.h_amplitude(~ind), ...
                'MarkerSize',obj.unselectedMarkerSize, ...
                'Color',obj.unselectedColor);
            
            drawnow limitrate
            
            obj.figure.Pointer = 'arrow';
            
            uistack([obj.h_meanwaveform; obj.h_waveforms(ind)],'top');
            
            tstr{1} = sprintf('%s - %d spikes',obj.Cluster.Name,obj.Cluster.N);
            tstr{2} = obj.Cluster.Session.Name;
            sgtitle(obj.maintiles,tstr);
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
            ind = ~ismember(s,obj.Cluster.Samples);
            delete(obj.h_waveforms(ind))
            obj.h_waveforms(ind) = [];
            
            s = cell2mat(get(obj.h_pca,'UserData'));
            ind = ~ismember(s,obj.Cluster.Samples);
            delete(obj.h_pca(ind));
            obj.h_pca(ind) = [];
            
            s = cell2mat(get(obj.h_amplitude,'UserData'));
            ind = ~ismember(s,obj.Cluster.Samples);
            delete(obj.h_amplitude(ind));
            obj.h_amplitude(ind) = [];                       
            
            delete(obj.h_meanwaveform);
            hold(obj.ax_waveforms,'on');
            obj.h_meanwaveform = obj.Cluster.plot_waveform_mean(obj.ax_waveforms);
            hold(obj.ax_waveforms,'off');
            
            obj.selectedSamples = [];

            obj.plot_density;
            obj.plot_isi;
            obj.plot_missing;
            obj.plot_firingrate;
            
        end
        
        function plot_density(obj)
            obj.h_density = obj.Cluster.plot_waveform_density(obj.ax_density);
            ylim(obj.ax_density,ylim(obj.ax_waveforms));
            title(obj.ax_density,'');
        end
        
        function plot_waveforms(obj)
            ax = obj.ax_waveforms;
            obj.h_waveforms = obj.Cluster.plot_waveforms(ax,'maxwf',inf);
            hold(ax,'on');
            obj.h_meanwaveform = obj.Cluster.plot_waveform_mean(ax);
            hold(ax,'off');
            set(obj.h_waveforms,'ButtonDownFcn',@obj.select_spike);
            title(ax,'');
        end
        
        function plot_pca(obj)
            ax = obj.ax_pca;
            [~,scores,~] = obj.Cluster.waveform_pca;
            for i = 1:size(scores,1)
                obj.h_pca(i) = line(ax,scores(i,1),scores(i,2),scores(i,3), ...
                    'LineStyle','none','Marker','.','MarkerSize',obj.unselectedMarkerSize, ...
                    'color',obj.unselectedColor,'UserData',obj.Cluster.Samples(i));
            end
            grid(ax,'on');
            box(ax,'on');
            xlabel(ax,'PC1');
            ylabel(ax,'PC2');
            zlabel(ax,'PC3');
            axis(ax,'tight');
            set(ax,'XTickLabel',[],'YTickLabel',[],'ZTickLabel',[]);
            view(ax,3);
            epa.helper.setfont(ax);
            set(obj.h_pca,'ButtonDownFcn',@obj.select_spike);
        end
        
        function plot_isi(obj)
            obj.h_isi = obj.Cluster.plot_interspike_interval(obj.ax_isi);
            obj.h_isi.rpv.FaceColor = 'm';
            box(obj.ax_isi,'on');
            title(obj.ax_isi,char(obj.h_isi.text.String),'interpreter','latex');
            delete(obj.h_isi.text);
        end
        
        
        function plot_amplitude(obj)
            obj.h_amplitude = obj.Cluster.plot_waveform_amplitudes(obj.ax_amplitude);
            set(obj.h_amplitude, ...
                'MarkerSize',obj.unselectedMarkerSize, ...
                'Color',obj.unselectedColor, ...
                'ButtonDownFcn',@obj.select_spike);
            title(obj.ax_amplitude,'peaks','interpreter','latex');
        end
        
        function plot_missing(obj)
            obj.h_missing = obj.Cluster.plot_missing_spikes_estimate(obj.ax_missing);
            title(obj.ax_missing,char(obj.h_missing.text.String),'interpreter','latex');
            delete(obj.h_missing.text);
        end
        function plot_firingrate(obj)
            obj.h_firingrate = obj.Cluster.plot_firingrates(obj.ax_firingrate);
            title(obj.ax_firingrate,'','interpreter','latex');
        end
        
        
        function create_roi(obj,type)
            
            switch lower(type)
                case 'waveform'                    
                    ax = obj.ax_waveforms;
                    roifnc = @drawrectangle;
                case 'amplitude'
                    ax = obj.ax_amplitude;
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
                case 'amplitude'
                    obj.roi_amplitude(end+1) = roi;
                case 'pca'
                    obj.roi_pca(end+1) = roi;
            end

            obj.update_roi(roi);
        end
        
        function update_roi(obj,roi,event)
            switch roi.UserData
                case 'waveform'
                    h = obj.h_waveforms;
                case 'amplitude'
                    h = obj.h_amplitude;
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
                case 'amplitude'
                     h = obj.h_amplitude;
                     
                    x = double(cell2mat(get(h,'XData')));
                    y = double(cell2mat(get(h,'YData')));
                    
                    ind = true(size(x,1),1);
                    for k = 1:length(obj.roi_amplitude)
                        roi = handle(obj.roi_amplitude(k));
                        k_ind = inpolygon(x,y,roi.Vertices(:,1),roi.Vertices(:,2));
                        k_ind = any(k_ind,2);
                        ind = ind & k_ind;
                    end
                    
                case 'waveform'
                    h = obj.h_waveforms;
                    
                    x = double(cell2mat(get(h,'XData')));
                    y = double(cell2mat(get(h,'YData')));
                    
                    ind = true(size(x,1),1);
                    for k = 1:length(obj.roi_waveform)
                        roi = handle(obj.roi_waveform(k));
                        k_ind = inpolygon(x,y,roi.Vertices(:,1),roi.Vertices(:,2));
                        k_ind = any(k_ind,2);
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
            t = tiledlayout(4,4,'Tag','MainTiles');
            obj.maintiles = t;
            
            
            % density
            obj.ax_density = nexttile(t,1,[2 2]);
            
            % waveforms
            obj.ax_waveforms = nexttile(t,3,[2 2]);
            
            % pca
            obj.ax_pca = nexttile(t,11,[2 2]);
            
            % isi
            obj.ax_isi = nexttile(t,9);
            
            % waveform amplitude over time
            obj.ax_amplitude = nexttile(t,10);
            
            % missing spikes estimate
            obj.ax_missing = nexttile(t,13);
            
            % firing rate
            obj.ax_firingrate = nexttile(t,14);
            
            obj.plot_waveforms;
            obj.plot_density;
            obj.plot_pca;
            obj.plot_isi;
            obj.plot_amplitude;
            obj.plot_missing;
            obj.plot_firingrate;
            
            obj.update_selection;
            
            
            obj.figure.WindowKeyPressFcn = @obj.key_processor;
            
        end
        
        
        
        function key_processor(obj,src,event)
            
            switch event.Character
                case {'/','?'}
                    fprintf('\n')
                    disp('Cluster Editor key bindings:')
                    disp('''?'' - show key bindings')
                    disp('''c'' - clear currently selected spikes')
                    disp('''d'' - delete currently selected spikes')
                    disp('''i'' - invert current selection')
                    disp('''p'' - use an region of interest selection method on the PCA scatter plot')
                    disp('''w'' - add a box threshold to select waveforms')
                    disp('''a'' - add a box threshold to select spikes from amplitude/time plot')
                    
                case 'a'
                    obj.create_roi('amplitude');

                case 'w'
                    obj.create_roi('waveform');

                case 'c'
                    obj.selectedSamples = [];
                    delete(obj.roi_pca); obj.roi_pca = [];
                    delete(obj.roi_waveform); obj.roi_waveform = [];
                    delete(obj.roi_amplitude); obj.roi_amplitude = [];
                    
                case 'd'
                    if isempty(obj.selectedSamples), return; end
                    str = sprintf('Delete %d of %d spikes?', ...
                        length(obj.selectedSamples),obj.Cluster.N);
                    b = questdlg(str,'Delete Spikes','Delete','Cancel','Cancel');
                    if isequal(b,'Cancel'), return; end
                    obj.figure.Pointer = 'watch'; 
                    sgtitle(obj.maintiles,{'';'updating...'});
                    drawnow
                    obj.remove_spikes;
                    obj.selectedSamples = [];
                    delete(obj.roi_pca); obj.roi_pca = [];
                    delete(obj.roi_waveform); obj.roi_waveform = [];
                    
                    obj.figure.Pointer = 'arrow';
                    
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
