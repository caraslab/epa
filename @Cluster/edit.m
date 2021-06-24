function h = edit(obj)


f = figure('Name',obj.TitleStr,'Color','w');


t = tiledlayout(f,2,4,'Tag','maintiles');




% density
ax = nexttile(t,1,[1 2]);
obj.plot_waveform_density(ax);
ax.Tag = 'density';




% raw and mean
ax = nexttile(t,3,[1 2]);
h_waveforms = obj.plot_waveforms(ax,inf);
hold(ax,'on');
h_mean = obj.plot_waveform_mean(ax);
hold(ax,'off');
axis(ax,'tight');

ax.Tag = 'waveforms';
ax.Title.String = '';

ax.UserData.h_waveforms = h_waveforms;
ax.UserData.h_mean = h_mean;

set(h_waveforms,'ButtonDownFcn',{@highlight,obj});



plot_pca(f,obj)


f.WindowKeyPressFcn = {@key_processor,obj};

if nargout == 0, clear h; end

function plot_pca(f,obj)

t = findobj(f,'Tag','maintiles');

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

ax.Tag = 'pca23';

set([h_pc12, h_pc13, h_pc23],'ButtonDownFcn',{@highlight,obj});



function highlight(src,event,obj)

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

pc = get(ax_pc,'Children');
pc = [pc{:}];

hp = get(pc,'UserData');
hp = cell2mat(hp);

h_pc = pc(hp == idx);

if event.Button == 1
    h_waveform.LineWidth = 2;
    h_waveform.Color = 'r';
    
    ind = h_waveform ~= ch;
    % restacking is very slow.....
    %ax_waveforms.Children = [hw_mean; h_waveform; ch(ind)];
    
    
    set(h_pc,'Color','r','MarkerSize',10);
else
    h_waveform.LineWidth = 1;
    h_waveform.Color = [.4 .4 .4];
    
    set(h_pc,'Color','k','MarkerSize',1);

end
set(f,'pointer','arrow');


function key_processor(src,event,obj)

f = src;


ax_pc        = findobj(f,'Type','axes','-and','-regexp','tag','^pca*');
ax_waveforms = findobj(f,'Type','axes','-and','tag','waveforms');
ax_density   = findobj(f,'Type','axes','-and','tag','density');

switch event.Character
    case '?'
        
    case 'r' % reset
        set(f,'pointer','watch'); drawnow
        hch = ax_waveforms.Children;
        hw = get(hch,'UserData');
        ind = cellfun(@isempty,hw);
        hch(ind) = [];
        set(hch,'LineWidth',1,'Color',[.4 .4 .4]);
        hpc = get(ax_pc,'Children');
        hpc = [hpc{:}];
        set(hpc,'Color','k','MarkerSize',1);
        set(f,'pointer','arrow');
        
    case 'd' % delete waveform
        h = findobj(ax_waveforms,'color','r');
        if isempty(h), return; end
        set(f,'pointer','watch'); drawnow
        idx = get(h,'UserData');
        if iscell(idx), idx = cell2mat(idx); end
        obj.rem_spikes(obj.Samples(idx));
        h = findobj(f,'color','r');
        delete(h);
        cla(ax_density,'reset');
        obj.plot_waveform_density(ax_density);
        ax_density.Tag = 'density';
       % plot_pca(f,obj)
        set(f,'pointer','arrow');

end

