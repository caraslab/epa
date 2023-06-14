classdef ParameterTable < handle
    
    properties
        plotStyle
    end
    
    properties (SetAccess = private)
        handles
    end
    
    properties (SetAccess = immutable)
        parent
    end
    
    methods
        function obj = ParameterTable(parent,plotStyle)
            if nargin == 0 || isempty(parent)
                parent = uifigure('Position',[400 230 350 400]);
                movegui(parent,'onscreen');
            end
            
            obj.parent = parent;
            
            obj.create;
            
            if nargin > 1 && ~isempty(plotStyle)
                obj.plotStyle = plotStyle;
            end
            
        end        
        
        function set.plotStyle(obj,ps)
            pt = epa.helper.plot_types;
            mustBeMember(ps,pt);
            
            tmpObj = epa.plot.(ps);
            
            p = epa.helper.get_settable_properties(tmpObj);

            D = p(:);
            for i = 1:length(p)
                v = tmpObj.(p{i});
                if isnumeric(v) || islogical(v)
                    v = mat2str(v);
                elseif iscell(v)
                    v = char(v);
                end
                D{i,2} = v;
            end
            obj.handles.ParameterTable.Data = D;
            obj.handles.PlotStyleLabel.Text = ps;
        end
        
        function data_changed(obj,src,event)
            
        end
    end
    
    methods (Access = private)
        function create(obj)
            ParGrid = uigridlayout(obj.parent);
            ParGrid.ColumnWidth = {'1x'};
            ParGrid.RowHeight   = {25,'1x'};
            
            h = uilabel(ParGrid);
            h.Text = '';
            h.FontSize = 20;
            h.FontName = 'Consolas';
            h.FontWeight = 'bold';
            obj.handles.PlotStyleLabel = h;
            
            
            h = uitable(ParGrid);
            h.DisplayDataChangedFcn = @obj.data_changed;
            h.RowName = {};
            h.ColumnName = {'Parameter','Value'};
            h.ColumnEditable = [false true];
            h.FontSize = 14;
            h.FontName = 'Consolas';
            obj.handles.ParameterTable = h;
        end
    end
    
end
