function create_nav(obj)

if isempty(obj.parent)
    % figure
    fpos = getpref('epa_DataViewer','FigurePosition',[150 300 850 460]);
    f = uifigure('Position',fpos);
    f.DeleteFcn = @obj.delete_fig;
    f.WindowKeyPressFcn = @obj.process_keys;
    movegui(f,'onscreen');
    obj.parent = f;
end


obj.handles.DataBrowser = f;





% main grid Layout
NavGrid = uigridlayout(obj.parent);
NavGrid.ColumnWidth = {'0.25x','0.3x','0.2x','0.3x'};
NavGrid.RowHeight   = {25,25,'1x'};
obj.handles.NavGrid = NavGrid;





% toolbar
TbarGrid = uigridlayout(NavGrid);
TbarGrid.Layout.Column = [1 length(NavGrid.ColumnWidth)];
TbarGrid.Layout.Row    = 1;
TbarGrid.ColumnWidth   = repmat({120},1,5);
TbarGrid.RowHeight     = {'1x'};
TbarGrid.Padding       = [5 0 5 0];
obj.handles.ToolbarGrid = TbarGrid;


iconPath = fullfile(matlabroot,'toolbox','matlab','icons');


h = uibutton(TbarGrid);
h.Icon = fullfile(iconPath,'demoicon.gif');
h.Tooltip = 'Check workspace for Session objects';
h.Text = 'Refresh';
h.ButtonPushedFcn = {@obj.select_session_updated,true};
obj.handles.LoadSessionToolbar = h;


h = uibutton(TbarGrid);
h.Icon = fullfile(iconPath,'file_open.png');
h.Tooltip = 'Load Session(s) from one or multiple files';
h.Text = 'Load Session';
h.ButtonPushedFcn = @obj.file_open;
obj.handles.LoadSessionToolbar = h;


% Session
h = uilabel(NavGrid);
h.Layout.Column = 1;
h.Layout.Row = 2;
h.FontWeight = 'bold';
h.Text = 'Sessions';

h = epa.ui.SelectObject(NavGrid,'epa.Session','uilistbox');
h.handle.Layout.Column = 1;
h.handle.Layout.Row = 3;
h.handle.Tag = 'SelectSession';
h.handle.Multiselect = 'on';
h.handle.Enable = 'off';
h.handle.Tooltip = 'Select a Session';
obj.handles.SelectSession = h;






% Datatype Tab Group
h = uitabgroup(NavGrid);
h.Layout.Column = 2;
h.Layout.Row = [2 3];
obj.handles.DataTypeTabGroup = h;
tg = h;





% Streams
h = uitab(tg,'Title','Streams');
obj.handles.StreamsTab = h;


StreamGrid = uigridlayout(h);
StreamGrid.ColumnWidth = {'1x'};
StreamGrid.RowHeight   = {'1x',100};
obj.handles.StreamGrid = StreamGrid;

h = epa.ui.SelectObject(StreamGrid,'epa.Stream','uilistbox');
h.handle.Enable = 'off';
h.handle.Tag = 'SelectStreams';
h.handle.Multiselect = 'on';
h.handle.Tooltip = 'Select Streams';
obj.handles.SelectStreams = h;


h = uibutton(StreamGrid);
h.Layout.Row = 2;
h.Layout.Column = 1;
h.Text = 'Convert for FieldTrip';
h.ButtonPushedFcn = @obj.convert_streams;
obj.handles.ConvertStreams = h;




% Clusters
h = uitab(tg,'Title','Clusters');
obj.handles.ClustersTab = h;

ClustGrid = uigridlayout(h);
ClustGrid.ColumnWidth = {'1x','1x'};
ClustGrid.RowHeight   = {'1x',50,30};
obj.handles.ClustGrid = ClustGrid;

h = epa.ui.SelectObject(ClustGrid,'epa.Cluster','uilistbox');
h.handle.Layout.Row = 1;
h.handle.Layout.Column = [1 2];
h.handle.Enable = 'off';
h.handle.Tag = 'SelectClusters';
h.handle.Multiselect = 'on';
h.handle.Tooltip = 'Select Clusters';
obj.handles.SelectClusters = h;

h = uilistbox(ClustGrid,'Tag','UnitTypeList');
h.Layout.Row = [2 3];
h.Layout.Column = 1;
h.Multiselect = 'on';
h.Items = ["SU","MSU","MU","Noise"];
h.Tooltip = 'Filter by Cluster type';
h.ValueChangedFcn = @obj.select_session_updated;
obj.handles.UnitTypeListbox = h;

h = uibutton(ClustGrid);
h.Layout.Row = [2 3];
h.Layout.Column = 2;
h.Text = 'Plot Waveforms';
h.ButtonPushedFcn = @obj.plot_spike_waveforms;
obj.handles.SpikeWaveformButton = h;




% select ClustersTab by default
obj.handles.DataTypeTabGroup.SelectedTab = obj.handles.ClustersTab;





% Events
EventGrid = uigridlayout(NavGrid);
EventGrid.Layout.Column = 3;
EventGrid.Layout.Row    = [2 3];
EventGrid.ColumnWidth = {55,'1x'};
EventGrid.RowHeight   = {25,'1x',25','1x'};
EventGrid.ColumnSpacing = 5;
EventGrid.RowSpacing = 5;
EventGrid.Padding = [0 0 0 0];
obj.handles.EventGrid = EventGrid;

% Event1
h = uilabel(EventGrid,'Text','Event 1:');
h.Layout.Column = 1;
h.Layout.Row = 1;

h = epa.ui.SelectObject(EventGrid,'epa.Event','uidropdown');
h.handle.Layout.Column = 2;
h.handle.Layout.Row = 1;
h.handle.Enable = 'off';
h.handle.Tag = 'SelectEvent1';
h.handle.Tooltip = 'Select Event 1';
obj.handles.SelectEvent1 = h;

h = uilistbox(EventGrid);
h.Layout.Column = [1 2];
h.Layout.Row = 2;
h.Enable = 'off';
h.Tag = 'SelectEvent1Values';
h.Multiselect = 'on';
obj.handles.SelectEvent1Values = h;

% Event2
h = uilabel(EventGrid,'Text','Event 2:');
h.Layout.Column = 1;
h.Layout.Row = 3;

h = epa.ui.SelectObject(EventGrid,'epa.Event','uidropdown');
h.handle.Layout.Column = 2;
h.handle.Layout.Row = 3;
h.handle.Enable = 'off';
h.handle.Tag = 'SelectEvent2';
h.handle.Tooltip = 'Select Event 2';
obj.handles.SelectEvent2 = h;

h = uilistbox(EventGrid);
h.Layout.Column = [1 2];
h.Layout.Row = 4;
h.Enable = 'off';
h.Tag = 'SelectEvent2Values';
h.Multiselect = 'on';
obj.handles.SelectEvent2Values = h;



% Process Tab Group
h = uitabgroup(NavGrid);
h.Layout.Column = length(NavGrid.ColumnWidth);
h.Layout.Row = [2 length(NavGrid.RowHeight)];
obj.handles.ProcessTabGroup = h;
tg = h;


% Plot
h = uitab(tg,'Title','Plot');
obj.handles.PlotTab = h;

PlotGrid = uigridlayout(h);
PlotGrid.ColumnWidth = {'1x','1x'};
PlotGrid.RowHeight = {25,'1x',25,'1x'};
PlotGrid.Padding = [0 0 0 0];
obj.handles.PlotGrid = PlotGrid;

h = uidropdown(PlotGrid,'CreateFcn',@obj.create_plotdropdown);
h.Layout.Column = [1 2];
h.Layout.Row    = 1;
h.ValueChangedFcn = @obj.plot_style_value_changed;
h.Enable = 'off';
obj.handles.SelectPlotStyle = h;

h = uilistbox(PlotGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 2;
h.ValueChangedFcn = @obj.plot_select_parameter;
obj.handles.ParameterList = h;

h = uieditfield(PlotGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 3;
h.ValueChangedFcn = @obj.plot_parameter_edit;
obj.handles.ParameterEdit = h;



PlotOptGrid = uigridlayout(PlotGrid);
PlotOptGrid.Layout.Column = [1 2];
PlotOptGrid.Layout.Row = 4;
PlotOptGrid.ColumnWidth = {'1x','1x'};
PlotOptGrid.RowHeight = [repmat({'1x'},1,4) {'fit'}];
obj.handles.PlotOptGrid = PlotOptGrid;

h = uibutton(PlotOptGrid);
h.Layout.Column = 1;
h.Layout.Row    = 1;
h.Text = '';
h.Icon = fullfile(iconPath,'file_open.png');
h.Tooltip = 'Load Plot Settings';
h.ButtonPushedFcn = @obj.plot_load_settings;
obj.handles.LoadPlotSettingsButton = h;

h = uibutton(PlotOptGrid);
h.Layout.Column = 2;
h.Layout.Row    = 1;
h.Text = '';
h.Icon = fullfile(iconPath,'file_save.png');
h.Tooltip = 'Save Plot Settings';
h.ButtonPushedFcn = @obj.plot_save_settings;
obj.handles.SavePlotSettingsButton = h;

h = uicheckbox(PlotOptGrid);
h.Layout.Column = 1;
h.Layout.Row = 2;
h.Text = 'reuse fig';
obj.handles.ReuseFigureCheck = h;

h = uicheckbox(PlotOptGrid);
h.Layout.Column = 2;
h.Layout.Row = 2;
h.Text = 'equal ylim';
obj.handles.EqualYLim = h;

h = uicheckbox(PlotOptGrid);
h.Layout.Column = [1 2];
h.Layout.Row = 3;
h.Text = 'flow tiling';
obj.handles.FlowTiling = h;

h = uibutton(PlotOptGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 4;
h.Text = 'Plot';
h.ButtonPushedFcn = @obj.launch_plot;
obj.handles.PlotButton = h;





% Analysis
h = uitab(tg,'Title','Analysis');
obj.handles.AnalyzeTab = h;

AnalysisGrid = uigridlayout(h);
AnalysisGrid.ColumnWidth = {'.8x','.2x'};
AnalysisGrid.RowHeight = {'.7x',25,'.3x',25,25};

h = uilistbox(AnalysisGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 1;
m = cellfun(@(a) a(1:end-2),epa.helper.available_metrics,'uni',0);
h.Items = m;
h.ItemsData = cellfun(@(a) ['epa.metric.' a],m,'uni',0);
h.ValueChangedFcn = @obj.metric_select;
obj.handles.SelectMetricListbox = h;

h = uibutton(AnalysisGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 2;
h.Text = 'Help on Metric';
h.Tooltip = 'Show help in the command window for the selected metric';
h.ButtonPushedFcn = @obj.metric_show_help;
obj.handles.HelpAnalysisButton = h;


h = uilistbox(AnalysisGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 3;
h.ValueChangedFcn = @obj.metric_select_parameter;
obj.handles.SelectMetricParameterListbox = h;

h = uieditfield(AnalysisGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 4;
h.ValueChangedFcn = @obj.metric_parameter_edit;
obj.handles.AnalysisParameterEdit = h;

h = uibutton(AnalysisGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 5;
h.Text = 'Run Analysis';
h.Tooltip = 'Run currently selected analysis';
h.ButtonPushedFcn = @obj.run_analysis;
obj.handles.RunAnalysisButton = h;




% Set fonts
epa.helper.setfont(obj.parent);




h = obj.handles;

addlistener(h.SelectSession, 'Updated',@obj.select_session_updated);
addlistener(h.SelectEvent1,  'Updated',@obj.select_event_updated);
addlistener(h.SelectEvent2,  'Updated',@obj.select_event_updated);
addlistener(h.SelectClusters,'Updated',@obj.select_cluster_updated);


obj.select_session_updated([],[],true);

obj.plot_style_value_changed;

obj.metric_select;








