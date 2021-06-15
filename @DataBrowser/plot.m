function pObj = plot(obj,src,event)

S = obj.curSession;
C = obj.curClusters;

E1 = obj.curEvent1;
E2 = obj.curEvent2;

if obj.handles.ReuseFigureCheck.Value == 0 || ~isfield(obj.Par,'parent') || isempty(obj.Par.parent) || ~isvalid(obj.Par.parent)
    f = figure('NumberTitle','off');
    f.Color = 'w';
    obj.Par.parent = f;
end
clf(obj.Par.parent);

ps = obj.curPlotStyle;
ps = ['epa.plot.' ps];

tmpObj = feval(ps,obj.curClusters(1));

par = obj.Par;

switch tmpObj.DataFormat
    case '1D'
        par.event = E1.Name;
        par.eventvalue = obj.handles.SelectEvent1Values.Value;
        
    case '2D'
        par.eventX = E1.Name;
        par.eventXvalue = obj.handles.SelectEvent1Values.Value;
        par.eventY = E2.Name;
        par.eventYvalue = obj.handles.SelectEvent2Values.Value;
        
    otherwise
        error('Unrecognized plot DataFormat, ''%s''',tmpObj.DataFormat)
end

par.showlegend = false;


% vvvv sloppy code... clean up at some point vvvvv
% if ~isequal(tmpObj.DataFormat,'2D') && (length(S) == 1 || length(C) == 1)
%     
%     if length(S) == 1
%         n = length(C);
%         A = C;
%     else
%         n = length(S);
%         A = S;
%     end
%     
%     uv = obj.curEvent1Values;
% 
%     m = length(uv);
%     
%     if obj.handles.FlowTiling.Value || m == 1 && n == 1
%         t = tiledlayout('flow');
%     else
%         t = tiledlayout(n,m);
%     end
%     
%     
%     for a = 1:length(A)
%         for e = 1:length(uv)
%             ax = nexttile(t);
%             
%             par.ax = ax;
%             
%             par.eventvalue = uv(e);
%             
%             if length(S) == 1
%                 pObj(e,a) = feval(ps,A(a),par);
%             else
%                 AC = A(a).find_Cluster(C.Name);
%                 pObj(e,a) = feval(ps,AC,par);
%             end
%             
%             pObj(e,a).plot;
%             
%             if length(uv) > 1
%                 pObj(e,a).ax.Title.String{end+1} = sprintf('%s = %1g%s',E1.Name,uv(e),E1.Units);
%             end
%             
%             if m > 1 && n > 1
%                 if e > 1
%                     pObj(e,a).ax.YAxis.Label.String = '';
%                 end
%                 
%                 if a < length(A)
%                     pObj(e,a).ax.XAxis.Label.String = '';
%                 end
%             end
%         end
%     end
% else

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
% end


if obj.handles.EqualYLim.Value == 1 && numel(ax) > 1
    ax = findobj(obj.Par.parent,'type','axes');
    y = cell2mat(get(ax,'ylim'));
    set(ax,'ylim',[min(y(:,1)) max(y(:,2))]);
end

f.UserData = t;


if nargout == 0, clear pObj; end

