function create_nav(obj)

if isempty(obj.parent)
    % figure
    fpos = getpref('epa_DataViewer','FigurePosition',[150 300 850 325]);
    f = uifigure('Position',fpos);
    f.DeleteFcn = @obj.delete_fig;
    f.WindowKeyPressFcn = @obj.process_keys;
    movegui(f,'onscreen');
    obj.parent = f;
end




% main grid Layout
NavGrid = uigridlayout(obj.parent);
NavGrid.ColumnWidth = {'0.3x','0.24x','0.13x','0.13x','0.2x'};
NavGrid.RowHeight   = {25,25,'1x'};
obj.handles.NavGrid = NavGrid;





% toolbar
TbarGrid = uigridlayout(NavGrid);
TbarGrid.Layout.Column = [1 5];
TbarGrid.Layout.Row    = 1;
TbarGrid.ColumnWidth   = repmat({120},1,5);
TbarGrid.RowHeight     = {'1x'};
TbarGrid.Padding       = [5 0 5 0];
obj.handles.ToolbarGrid = TbarGrid;


iconPath = fullfile(matlabroot,'toolbox','matlab','icons');


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


h = uitabgroup(NavGrid);
h.Layout.Column = 2;
h.Layout.Row = [2 3];
obj.handles.TabGroup = h;
tg = h;


% Streams
h = uitab(tg,'Title','Streams');
obj.handles.StreamsTab = h;

StreamGrid = uigridlayout(h);
StreamGrid.ColumnWidth = {'1x'};
StreamGrid.RowHeight   = {'1x'};
obj.handles.ClustGrid = StreamGrid;

h = epa.ui.SelectObject(StreamGrid,'epa.Stream','uilistbox');
h.handle.Enable = 'off';
h.handle.Tag = 'SelectStreams';
h.handle.Multiselect = 'on';
h.handle.Tooltip = 'Select Streams';
obj.handles.SelectClusters = h;


% Clusters
h = uitab(tg,'Title','Clusters');
obj.handles.ClustersTab = h;

ClustGrid = uigridlayout(h);
ClustGrid.ColumnWidth = {'1x'};
ClustGrid.RowHeight   = {'1x'};
obj.handles.ClustGrid = ClustGrid;

h = epa.ui.SelectObject(ClustGrid,'epa.Cluster','uilistbox');
h.handle.Enable = 'off';
h.handle.Tag = 'SelectClusters';
h.handle.Multiselect = 'on';
h.handle.Tooltip = 'Select Clusters';
obj.handles.SelectClusters = h;

% select ClustersTab by default
obj.handles.TabGroup.SelectedTab = obj.handles.ClustersTab;


% Event1
h = epa.ui.SelectObject(NavGrid,'epa.Event','uidropdown');
h.handle.Layout.Column = 3;
h.handle.Layout.Row = 2;
h.handle.Enable = 'off';
h.handle.Tag = 'SelectEvent1';
h.handle.Tooltip = 'Select Event 1';
obj.handles.SelectEvent1 = h;

h = uilistbox(NavGrid);
h.Layout.Column = 3;
h.Layout.Row = 3;
h.Enable = 'off';
h.Tag = 'SelectEvent1Values';
h.Multiselect = 'on';
obj.handles.SelectEvent1Values = h;

% Event2
h = epa.ui.SelectObject(NavGrid,'epa.Event','uidropdown');
h.handle.Layout.Column = 4;
h.handle.Layout.Row = 2;
h.handle.Enable = 'off';
h.handle.Tag = 'SelectEvent2';
h.handle.Tooltip = 'Select Event 2';
obj.handles.SelectEvent2 = h;

h = uilistbox(NavGrid);
h.Layout.Column = 4;
h.Layout.Row = 3;
h.Enable = 'off';
h.Tag = 'SelectEvent2Values';
h.Multiselect = 'on';
obj.handles.SelectEvent2Values = h;





% Plot
PlotGrid = uigridlayout(NavGrid);
PlotGrid.ColumnWidth = {'1x','1x'};
PlotGrid.RowHeight = {25,'1x',25,50};
PlotGrid.Padding = [0 0 0 0];
PlotGrid.Layout.Column = 5;
PlotGrid.Layout.Row = [2 length(NavGrid.RowHeight)];
obj.handles.PlotGrid = PlotGrid;

h = uidropdown(PlotGrid,'CreateFcn',@obj.create_plotdropdown);
h.Layout.Column = [1 2];
h.Layout.Row    = 1;
h.ValueChangedFcn = @obj.plot_style_value_changed;
obj.handles.SelectPlotStyle = h;

h = uilistbox(PlotGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 2;
h.ValueChangedFcn = @obj.select_parameter;
obj.handles.ParameterList = h;

h = uieditfield(PlotGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 3;
h.ValueChangedFcn = @obj.parameter_edit;
obj.handles.ParameterEdit = h;

h = uibutton(PlotGrid);
h.Layout.Column = [1 2];
h.Layout.Row    = 4;
h.Text = 'Plot';
h.ButtonPushedFcn = @obj.plot;
obj.handles.PlotButton = h;


obj.handles.AutoUpdatePlotButton = h;




h = obj.handles;

% Set fonts
epa.helper.setfont(obj.parent,12);





addlistener(h.SelectSession, 'Updated',@obj.select_session_updated);
addlistener(h.SelectEvent1,  'Updated',@obj.select_event_updated);
addlistener(h.SelectEvent2,  'Updated',@obj.select_event_updated);
addlistener(h.SelectClusters,'Updated',@obj.select_cluster_updated);


obj.select_session_updated('init');

obj.plot_style_value_changed;