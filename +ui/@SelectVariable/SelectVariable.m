classdef SelectVariable < handle
% obj = SelectVariable(parent,[variableClass],[searchStr],[workspace])
%
% parent        ... handle to parent container, such as figure, uifigure,
%                   uipanel, uigridlayout, etc.
% variableClass ... Optional. Limit variables listed to a specific class
%                   type. ex: 'double'
% searchStr     ... Optional. Limit variables listed to a specific search
%                   string. ex: 'data_*'
% workspace     ... Optional. Specify the workspace to look for variables.
%                   Default = 'base'.
% 
% Use the obj.refresh function to look for new variables in the specified
% workspace.
% 
% 
% DJS 2021
    
    properties (SetObservable = true)
        Variable
        variableClass   (1,:) char
        workspace       (1,:) char = 'base';
        searchStr       (1,:) char
    end
    
    properties (Dependent)
        AvailableVars
    end
    
    properties (SetAccess = immutable)
        handle
        parent
    end
    
    events
        Updated
    end
    
    methods
        
        function obj = SelectVariable(parent,variableClass,searchStr,workspace)
            
            if nargin < 2, variableClass = ''; end
            if nargin < 3, searchStr = ''; end
            if nargin < 4, workspace = 'base'; end
            
            obj.parent = parent;
            obj.variableClass = variableClass;
            obj.searchStr = searchStr;
            obj.workspace = workspace;
            
            obj.handle = obj.create;
            obj.refresh;
        end
        
        function a = get.AvailableVars(obj)
            a = evalin(obj.workspace,sprintf('whos(%s);',obj.searchStr));
            if isempty(obj.variableClass)
                ind = true(size(a));
            else
                ind = ismember({a.class},obj.variableClass);
            end
            a = [a(ind).name];
        end
        
        function value_changed(obj,src,evnt)
            notify(obj,'Updated',evnt);
        end
        
        function refresh(obj,src,event)
            v = obj.AvailableVars;
            
            if isempty(v), v = "---"; end
            
            obj.handle.Items = v;
            obj.handle.ItemsData = obj.Object;
            obj.handle.Value = obj.Object(1);
        end
    end
    
    methods (Access = protected)
        function h = create(obj)
            h = uidropdown(obj.parent);
            h.Editable = false;
            h.Tooltip = sprintf('Select a variable of type %s',obj.variableClass);
            h.ValueChangedFcn = @obj.value_changed;
            h.UserData = obj;
        end
    end
end