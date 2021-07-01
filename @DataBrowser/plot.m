function pObj = plot(obj,src,event)

S = obj.curSession;
C = obj.curClusters;

E1 = obj.curEvent1;
E2 = obj.curEvent2;

if obj.handles.ReuseFigureCheck.Value == 0 || ~isfield(obj.plotSettings,'parent') || isempty(obj.plotSettings.parent) || ~isvalid(obj.plotSettings.parent)
    f = figure('NumberTitle','off');
    f.Color = 'w';
    obj.plotSettings.parent = f;
end
clf(obj.plotSettings.parent);

ps = obj.curPlotStyle;
ps = ['epa.plot.' ps];

tmpObj = feval(ps,obj.curClusters(1));

par = obj.plotSettings;

switch tmpObj.DataFormat
    case '1D'
        par.event = E1.Name;
        par.eventvalue = obj.curEvent1Values;
        
    case '2D'
        par.eventX = E1.Name;
        par.eventXvalue = obj.curEvent1Values;
        par.eventY = E2.Name;
        par.eventYvalue = obj.curEvent2Values;
        
    otherwise
        error('Unrecognized plot DataFormat, ''%s''',tmpObj.DataFormat)
end

par.showlegend = false;

m = length(C);
n = length(S);

if  obj.handles.FlowTiling.Value || m == 1 || n == 1
    t = tiledlayout('flow');
else
    t = tiledlayout(m,n);
end


for s = 1:length(S)
    for c = 1:length(C)
        ax = nexttile(t);
        par.ax = ax;
        
        SC = S(s).find_Cluster(C(c).Name);
        pObj(c,s) = feval(ps,SC,par);
        pObj(c,s).plot;
    end
end



if obj.handles.EqualYLim.Value == 1 && numel(ax) > 1
    ax = findobj(obj.plotSettings.parent,'type','axes');
    y = cell2mat(get(ax,'ylim'));
    set(ax,'ylim',[min(y(:,1)) max(y(:,2))]);
end

f.UserData = t;


if nargout == 0, clear pObj; end

