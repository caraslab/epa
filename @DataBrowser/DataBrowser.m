classdef DataBrowser < handle
    
    properties (SetObservable = true)
        Session
        plotSettings
    end
    
    properties
        Filename    (:,1) string
        DataPath    (:,1) string
    end
    
    
    properties (Access = public) % make protected
        handles
        plotMeta
    end
    
    properties (SetAccess = private)
        parent
    end
    
    properties (Dependent)
        curEvent1
        curEvent2
        curEvent1Values
        curEvent2Values
        curClusters
        curSession
        curPlotStyle
        curMetric
        curMetricParameter
    end
    
    
    methods
        create_nav(obj);
        plot(obj,src,event);
        
        function obj = DataBrowser(varargin)
            

            if length(varargin) > 1
                par = epa.helper.parse_params(obj,varargin{:});
                
                fn = fieldnames(par);
                for i = 1:length(fn)
                    obj.(fn{i}) = par.(fn{i});
                end
            end
            
            
            obj.create_nav;
            
            if nargin > 0 && isa(varargin{1},'epa.Session')
                obj.Session = varargin{1};
            end
            
            if nargout == 0, clear obj; end
        end
        
        function delete(obj)
            if isvalid(obj.parent), delete(obj.parent); end
        end
        
        
        function delete_fig(obj,src,event)
            if isa(obj.parent,'matlab.ui.Figure')
                setpref('epa_DataViewer','FigurePosition',obj.parent.Position);
            end
            delete(obj.parent);
        end
        
        
        
        
        function o = get.curClusters(obj)
            o = obj.handles.SelectClusters.CurrentObject;
        end
        
        
        function o = get.curEvent1(obj)
            o = obj.handles.SelectEvent1.CurrentObject;
        end
        
        function o = get.curEvent2(obj)
            o = [];
            if length(obj.curSession(1).Events) > 1
                o = obj.handles.SelectEvent2.CurrentObject;
            end
        end
        
        function v = get.curEvent1Values(obj)
            v = obj.handles.SelectEvent1Values.Value;
        end
        
        function v = get.curEvent2Values(obj)
            v = obj.handles.SelectEvent1Values.Value;
        end
        
        
        function s = get.curPlotStyle(obj)
            s = obj.handles.SelectPlotStyle.Value;
        end
        
        
        function m = get.curMetric(obj)
            m = obj.handles.SelectMetricListbox.Value;
        end
        
        function p = get.curMetricParameter(obj)
            p = obj.handles.SelectMetricParameterListbox.Value;
        end
        
        function o = get.curSession(obj)
            o = obj.handles.SelectSession.CurrentObject;
        end
        
        function set.Session(obj,S)            
            
            if isempty(S), return; end
            
            obj.Session = S;
            
            h = obj.handles.SelectSession;
            h.Object =S;
            
            % add running index to Session
            for i = 1:length(h.handle.Items)
                h.handle.Items{i} = sprintf('%02d. %s',i,h.handle.Items{i});
            end
        end
        
        
        function change_data_path(obj,src,event)
            pth = getpref('epa_DataViewer','DataPath',string(cd));
            
            pth = uigetdir(pth,'Data Path');
            
            if isequal(pth,0), return; end
            
            obj.DataPath = string(pth);
            
            d = dir(fullfile(pth,'*.mat'));
                        
            fn = arrayfun(@(a) fullfile(a.folder,a.name),d,'uni',0);
            
            obj.Filename = string(fn);
            
            setpref('epa_DataViewer','DataPath',pth);
        end
        
        
        
        function file_open(obj,src,event)
            
            pth = getpref('epa_DataViewer','DataPath',string(cd));
            
            [fn,pth] = uigetfile( ...
                {'*.mat','MAT-file (*.mat)'; ...
                '*.epas','Session Object (*.mat)'}, ...
                'Pick a file',pth,'MultiSelect','on');
            
            if isequal(fn,0), return; end
                        
            fn = cellfun(@(a) fullfile(pth,a),cellstr(fn),'uni',0);
            obj.Filename = string(fn);
            
            setpref('epa_DataViewer','DataPath',pth);

        end
        
        
        function set.Filename(obj,fn)
            fn = string(fn);
            
            
            % look for epa.Session objects within files within the selected
            % directory
            
            S = [];
            for i = 1:length(fn)
                assert(isfile(fn(i)),'epa:DataBrowser:set_Filename:FileNotFound', ...
                    'The file "%s" was not found.',fn(i));
                
                r = load(fn(i),'-mat');
                nmf = fieldnames(r);
                t = cellfun(@(a) isa(r.(a),'epa.Session'),nmf,'uni',0);
                for j = 1:length(nmf)
                    nmf{j}(~t{j}) = [];
                    if isempty(nmf{j}), continue; end
                    if isempty(S)
                        S = r.(nmf{j})(:);
                    else
                        S = [S(:); r.(nmf{j})(:)];
                    end
                end
            end
            obj.Session = S;
            obj.Filename = fn;
            
            figure(ancestor(obj.parent,'figure'));
        end
        
        
        
    end % methods (Access = public)
    
    
    
    
    
    
    methods (Access = private)
        function create_plotdropdown(obj,src,event)
            plottypes = epa.helper.plot_types;
            src.Items     = plottypes;
            src.ItemsData = plottypes;
            src.Value     = 'PSTH';
        end
        
        
        
        function select_session_updated(obj,src,event)
            
            h = obj.handles;
            
            if nargin > 1 && isequal(src,'init')
                a = evalin('base','whos'); 
                ind = ismember({a.class},'epa.Session');
                
                if isempty(ind) || ~any(ind)
                    return
                end
                
                an = string({a(ind).name});
                b = cellfun(@(x) evalin('base',x),an,'uni',0);
                % add variable name and index values to Session array; there must be a
                % simpler way to do this...
                ann = string([]);
                for i = 1:length(b)
                    for j = 1:numel(b{i})
                        ann(end+1) = sprintf('[%s(%d)] %s',an(i),j,b{i}(j).Name);
                    end
                end
                h.SelectSession.Object = [b{:}];
                h.SelectSession.handle.Items = ann;
                
                % add running index to Session
                for i = 1:length(h.SelectSession.handle.Items)
                    h.SelectSession.handle.Items{i} = sprintf('%02d. %s',i,h.SelectSession.handle.Items{i});
                end
            end
            
            
            S = h.SelectSession.CurrentObject;
            
            if isempty(S)
                h.SelectClusters.handle.Items = {};
                h.SelectClusters.handle.Enable = 'off';
                h.SelectEvent1.handle.Items = {};
                h.SelectEvent1.handle.Enable ='off';
                h.SelectEvent2.handle.Items = {};
                h.SelectEvent2.handle.Enable ='off';
                h.SelectEvent1Values.Items = {};
                h.SelectEvent1Values.Enable = 'off';
                h.SelectEvent2Values.Items = {};
                h.SelectEvent2Values.Enable = 'off';
                h.PlotButton.Enable = 'off';
                h.SelectPlotStyle.Enable = 'off';
                return
            end
                        
            h.SelectSession.handle.Enable  = 'on';
            h.SelectClusters.handle.Enable = 'on';
            h.SelectEvent1.handle.Enable   = 'on';
            h.SelectEvent2.handle.Enable   = 'on';
            h.SelectEvent1Values.Enable    = 'on';
            h.SelectEvent2Values.Enable    = 'on';
            h.SelectPlotStyle.Enable       = 'on';
            
            % update Events
            E = S.common_Events;

            if isempty(E)
                h.SelectEvent1.handle.Enable   = 'off';
                h.SelectEvent2.handle.Enable   = 'off';
                h.SelectEvent1Values.Enable    = 'off';
                h.SelectEvent2Values.Enable    = 'off';
                h.SelectPlotStyle.Enable       = 'off';
                uialert(obj.parent,'No Events were found to be in common across the selected Sessions.', ...
                    'No Events','Icon','warning','Modal',true);
                return
            end
            
            h.SelectEvent1.Object   = E;                        
            obj.select_event_updated(h.SelectEvent1);
            if length(E) > 1
                h.SelectEvent2.Object  = E;
                h.SelectEvent2.CurrentObject = E(2);
                obj.select_event_updated(h.SelectEvent2);
            else
                h.SelectEvent2.handle.Enable = 'off';
                h.SelectEvent2Values.Enable = 'off';
            end
            
            
            
            % update Clusters
            C = S.common_Clusters;
            
            selectedUnitTypes = string(h.UnitTypeListbox.Value);
            if isempty(selectedUnitTypes)
                selectedUnitTypes = h.UnitTypeListbox.Items;
            end
            ind = ismember([C.Type],selectedUnitTypes);
            C(~ind) = [];
            
            if isempty(C)
                h.SelectClusters.handle.Enable = 'off';
                h.PlotButton.Enable = 'off';
                uialert(obj.parent,'No Clusters were found to be in common across the selected Sessions.', ...
                    'No Clusters','Icon','warning','Modal',true);
                return
            end
            h.PlotButton.Enable = 'on';
            
            h.SelectClusters.Object = C;
            h.SelectClusters.handle.Items = {C.TitleStr};
            obj.select_cluster_updated;
            
            
            
            % update Streams
            
            
            
            
            h.SelectPlotStyle.Enable = 'on';
        end
        
        function select_event_updated(obj,src,event)
            h = obj.handles.(sprintf('%sValues',src.handle.Tag));
            
            dv = src.CurrentObject.DistinctValues;
            dvstr = cellstr(num2str(dv));
            
            h.Items     = dvstr;
            h.ItemsData = dv;
            h.Value     = dv;
        end
        
        function select_cluster_updated(obj,src,event)
            h = obj.handles;
            c = obj.curClusters;
            if isempty(c)
                h.PlotButton.Enable = 'off';
                h.SelectClusters.handle.Tooltip = "";
            else
                h.PlotButton.Enable = 'on';
                if numel(c) == 1
                    if isempty(c.Note)
                        h.SelectClusters.handle.Tooltip = c.TitleStr;
                    else
                        h.SelectClusters.handle.Tooltip = c.Note;
                    end
                else
                    h.SelectClusters.handle.Tooltip = {c.TitleStr};
                end
            end
        end
        
        function plot_select_parameter(obj,src,event)
            h = obj.handles;
            
            pv = h.ParameterList.Value;
            
            v = obj.plotSettings.(pv);
            if isempty(v)
                h.ParameterEdit.Value = '[]';
            elseif isstring(v) || ischar(v)
                h.ParameterEdit.Value = v;
            elseif iscell(v)
                h.ParameterEdit.Value = v{1};
            else
                h.ParameterEdit.Value = mat2str(v);
            end
            
            if ~isempty(obj.plotMeta)
                p = obj.plotMeta.PropertyList;
                p = p(ismember({p.Name},pv));
                str = epa.helper.metaprop2str(p);
                
                h.ParameterEdit.Tooltip = str;
            end
        end
        
        
        function plot_parameter_edit(obj,src,event)
            h = obj.handles;
            
            p = h.ParameterList.Value;
            
            nv = event.Value;
            
            if ~isvalid(obj.plotMeta), return; end
            
            mp = obj.plotMeta.PropertyList;
            
            
            if isnumeric(obj.plotSettings.(p)) || islogical(obj.plotSettings.(p))
                nv = str2num(nv);
            end
            
            ind = ismember({mp.Name},p);
            m = mp(ind);
            
            

            if isValidValue(m.Validation,nv)
                obj.plotSettings.(p) = nv;
                src.BackgroundColor = [0.4 1 0.4]; 
                pause(0.3);
                src.BackgroundColor = [1 1 1];
            else
                src.BackgroundColor = [1 0.4 0.4];
                pause(0.3);
                src.BackgroundColor = [1 1 1];
                h.ParameterEdit.Value = event.PreviousValue;
            end
            
        end
        
        
        function plot_style_value_changed(obj,src,event)
            h = obj.handles;
            
            pst = obj.curPlotStyle;
                
            tmpObj = epa.plot.(pst);
            
            p = epa.helper.get_settable_properties(tmpObj);
            
            obj.plotMeta = metaclass(tmpObj);
            
            h.ParameterList.Items = sort(p);
            
            obj.plotSettings = [];
            for i = 1:length(p)
                obj.plotSettings.(p{i}) = tmpObj.(p{i});
            end
            
            obj.plot_select_parameter;

        end
        
        function launch_plot(obj,src,event)
            h = obj.handles;
            h.PlotButton.Text = 'Plotting...';
            h.PlotButton.Enable = 'off';
            drawnow
            try
                obj.plot;
                h.PlotButton.Text = 'Plot';
                h.PlotButton.Enable = 'on';
            catch me
                h.PlotButton.Text = 'Plot';
                h.PlotButton.Enable = 'on';
                rethrow(me)
            end
        end
        
        function plot_save_settings(obj,src,event)
            plotSettings = obj.plotSettings;
            plotStyle = obj.curPlotStyle;
            
            pth = getpref('epa_DataBrowser','PlotSettings',cd);
            
            [fn,pth] = uiputfile({'*.mat','MAT-files (*.mat'}, ...
                'Save Plot Settings',pth);
            
            if isequal(fn,0), return; end
            
            ffn = fullfile(pth,fn);
            

            save(ffn,'plotSettings','plotStyle');
            
            setpref('epa_DataBrowser','PlotSettings',pth);
            
            fprintf('Current plot settings saved to: "%s"\n',ffn)
        end
        
        function plot_load_settings(obj,src,event)
            
            pth = getpref('epa_DataBrowser','PlotSettings',cd);
            
            [fn,pth] = uigetfile({'*.mat','MAT-files (*.mat'}, ...
                'Load Plot Settings',pth);
            
            if isequal(fn,0), return; end
            
            ffn = fullfile(pth,fn);

            load(ffn,'plotSettings','plotStyle');
            
            setpref('epa_DataBrowser','PlotSettings',pth);
            
            
            obj.handles.SelectPlotStyle.Value = plotStyle;
            obj.plot_style_value_changed;
            obj.plotSettings = plotSettings; %#ok<PROPLC>
            
            fprintf('Updated plot settings saved from: "%s"\n',ffn)
            
            figure(ancestor(obj.parent,'figure'));
        end
        
        
        
        
        
        
        
        
        
        function metric_select(obj,src,event)            
            h = obj.handles;
            
            v = obj.curMetric;
            
            fprintf('\n\n%s\n\n',repmat('v',1,50))
            fprintf('help for the function "%s"\n\n',v)
            help(v)
            fprintf([repmat('^',1,50) '\n'])
            
            
            try
                dfltpar = feval(v,'getdefaults');
                fn = fieldnames(dfltpar);
            catch
                dfltpar = struct('fail',1);
                fn = {'< no parameters or error >'};
            end
            
            ph = h.SelectMetricParameterListbox;
            ph.Items = fn;
            ph.UserData = dfltpar;
            
            obj.metric_select_parameter;
        end
        
        function metric_select_parameter(obj,src,event)
            h = obj.handles;
            
            dfltpar = h.SelectMetricParameterListbox.UserData;
            
            v = obj.curMetricParameter;
            
            m = mat2str(dfltpar.(v));
            
            if isequal(m,'[]')
                m = '< no default >';
            end
            
            h.AnalysisParameterEdit.Value = m;
            
        end
        
        function metric_parameter_edit(obj,src,event)
            h = obj.handles;
            
        end
        
        
        
        
        
        
        
        
        
        
        function process_keys(obj,src,event)
            
        end
        
    end
    
end
