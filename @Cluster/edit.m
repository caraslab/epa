function h = edit(obj)


f = figure('Name',obj.TitleStr,'Color','w');

update_all_plots(f,obj)

f.WindowKeyPressFcn = {@key_processor,obj};

if nargout == 0, clear h; end
end

function update_all_plots(f,obj)

set(f,'pointer','watch'); drawnow

clf(f)


t = tiledlayout(f,2,4,'Tag','maintiles');


% raw and mean
ax = nexttile(t,3,[1 2]);
h_waveforms = obj.plot_waveforms(ax,inf);
hold(ax,'on');
h_mean = obj.plot_waveform_mean(ax);
hold(ax,'off');
ax.Tag = 'waveforms';
ax.Title.String = '';

ax.UserData.h_waveforms = h_waveforms;
ax.UserData.h_mean = h_mean;

set(h_waveforms,'ButtonDownFcn',{@select_spike,obj});

ax_waveforms = ax;



% density
ax = nexttile(t,1,[1 2]);
obj.plot_waveform_density(ax);
ax.Tag = 'density';
ylim(ax,ylim(ax_waveforms));

% pca scatter
[~,scores,~] = obj.waveform_pca;


ax = nexttile(t,6);
for i = 1:size(scores,1)
    h_pc12(i) = line(ax,scores(i,1),scores(i,2), ...
        'LineStyle','none','Marker','.','MarkerSize',1, ...
        'color','k','UserData',i);
end
grid(ax,'on');
xlabel(ax,'PC1');
ylabel(ax,'PC2');
axis(ax,'tight');
box(ax,'on');
set(ax,'XTickLabel',[],'YTickLabel',[])
ax.Tag = 'pca12';



ax = nexttile(t,7);
for i = 1:size(scores,1)
    h_pc13(i) = line(ax,scores(i,1),scores(i,3), ...
        'LineStyle','none','Marker','.','MarkerSize',1, ...
        'Color','k','UserData',i);
end
grid(ax,'on');
xlabel(ax,'PC1');
ylabel(ax,'PC3');
axis(ax,'tight');
box(ax,'on');
set(ax,'XTickLabel',[],'YTickLabel',[])
ax.Tag = 'pca13';


ax = nexttile(t,8);
for i = 1:size(scores,1)
    h_pc23(i) = line(ax,scores(i,2),scores(i,3), ...
        'LineStyle','none','Marker','.','MarkerSize',1, ...
        'Color','k','UserData',i);
end
grid(ax,'on');
xlabel(ax,'PC2');
ylabel(ax,'PC3');
axis(ax,'tight');
box(ax,'on');
set(ax,'XTickLabel',[],'YTickLabel',[])

ax.Tag = 'pca23';

set([h_pc12, h_pc13, h_pc23],'ButtonDownFcn',{@select_spike,obj});

set(f,'pointer','arrow');

end

function select_spike(src,event,obj)

idx = src.UserData;

f = ancestor(src,'figure');


set(f,'pointer','watch'); drawnow

ax_waveforms = findobj(f,'tag','waveforms');
ch = ax_waveforms.Children;
hw = get(ch,'UserData');
i = cellfun(@isempty,hw);
hw_mean = ch(i);
hw(i) = []; hw = cell2mat(hw);
ch(i) = [];

h_waveform = ch(hw == idx);

ax_pc = findobj(f,'-regexp','tag','^pca*');

pc = findobj(ax_pc,'type','Line');

hp = get(pc,'UserData');
hp = cell2mat(hp);

h_pc = pc(hp == idx);

if event.Button == 1
    h_waveform.LineWidth = 2;
    h_waveform.Color = 'r';
    
    set(h_pc,'Color','r','MarkerSize',10);
    drawnow
    
    % restacking is very slow.....
    ind = h_waveform ~= ch;
    ax_waveforms.Children = [hw_mean; h_waveform; ch(ind)];
    
    
else
    h_waveform.LineWidth = 1;
    h_waveform.Color = [.4 .4 .4];
    
    set(h_pc,'Color','k','MarkerSize',1);
    
end
set(f,'pointer','arrow');

end

function key_processor(f,event,obj)


ax_pc        = findobj(f,'Type','axes','-and','-regexp','tag','^pca*');
ax_waveforms = findobj(f,'Type','axes','-and','tag','waveforms');

switch event.Character
    case '?'
        
    case 'x' % reset
        reset_selection(f)
        
    case 'd' % delete spikes
        roi = findobj(f,'type','images.roi.Freehand');
        if isempty(roi)
            h = findobj(ax_waveforms,'color','r');
            if isempty(h), return; end
            idx = get(h,'UserData');
            if iscell(idx), idx = cell2mat(idx); end
            obj.rem_spikes(obj.Samples(idx));
            update_all_plots(f,obj)
        else
            delete_roi(roi);
        end
        
        
    case 'k' % keep waveforms
        
        
    case 'r' % create a freehand roi in current axes
        create_roi(obj);
        
        
        
end

end


function create_roi(obj)

ax = gca;

roi = drawfreehand(ax,'LineWidth',0.5,'UserData',obj, ...
    'FaceAlpha',0.1,'LabelVisible','hover', ...
    'LineWidth',0.5);

addlistener(roi,'MovingROI',@update_roi);
addlistener(roi,'ROIMoved',@update_roi);
addlistener(roi,'WaypointAdded',@update_roi);
addlistener(roi,'RemovingWaypoint',@update_roi);
addlistener(roi,'DrawingStarted',@update_roi);
addlistener(roi,'DrawingFinished',@update_roi);


addlistener(roi,'DeletingROI',@reset_selection);

update_roi(roi,[]);
end

function update_roi(roi,event)
ax = roi.Parent;

f = ancestor(ax,'figure');

ch = findobj(ax,'type','Line');

x = double([ch.XData]);
y = double([ch.YData]);

tf = inROI(roi,x,y);
idx = [ch.UserData];

ax_waveforms = findobj(f,'tag','waveforms');
wch = ax_waveforms.Children;
hw = get(wch,'UserData');
i = cellfun(@isempty,hw);
hw(i) = []; hw = cell2mat(hw);
wch(i) = [];

h_selectedwf = wch(ismember(hw,idx(tf)));
h_notselectedwf = wch(ismember(hw,idx(~tf)));

set(h_selectedwf,'LineWidth',2,'Color','r');
set(h_notselectedwf,'LineWidth',1,'Color',[.4 .4 .4]);

set(ch(tf),'Color','r','MarkerSize',10);
set(ch(~tf),'Color','k','MarkerSize',1);


roi.Label = sprintf('%d of %d',sum(tf),length(tf));

drawnow limitrate
end


function delete_roi(roi)

ax = roi.Parent;
ch = findobj(ax,'type','Line');

x = double([ch.XData]);
y = double([ch.YData]);

tf = inROI(roi,x,y);

idx = [ch.UserData];
idx(~tf) = [];

obj = roi.UserData;
obj.rem_spikes(obj.Samples(idx));

delete(roi);

update_all_plots(ancestor(ax,'figure'),obj)

end

function reset_selection(f,varargin)
if ~isa(f,'matlab.ui.Figure')
    f = gcf;
end
set(f,'pointer','watch'); drawnow


ax_pc        = findobj(f,'Type','axes','-and','-regexp','tag','^pca*');
ax_waveforms = findobj(f,'Type','axes','-and','tag','waveforms');


hch = ax_waveforms.Children;
hw = get(hch,'UserData');
ind = cellfun(@isempty,hw);
hch(ind) = [];
set(hch,'LineWidth',1,'Color',[.4 .4 .4]);
hpc = findobj(ax_pc,'type','Line');
set(hpc,'Color','k','MarkerSize',1);
set(f,'pointer','arrow');
end