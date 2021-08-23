classdef (Abstract = true) DataInterface < handle & matlab.mixin.SetGet & dynamicprops
    
    properties
        Name           (1,1) string
        ElectrodeIndex (1,1) double {mustBePositive,mustBeInteger} = 1;
        UserData
    end
    
    properties (SetAccess = protected)
        Session      (1,1) %epa.Session
    end
    
    properties (Dependent)
        thisfunc
    end
    
    methods (Abstract)
    end
    
    methods
        
        function c = copy(obj)
            if numel(obj) > 1
                c = arrayfun(@copy,obj);
                return
            end
            p = epa.helper.obj2par(obj);
            c = feval(obj.thisfunc,p.Session);
            p = rmfield(p,'Session');
            epa.helper.par2obj(c,p);
        end
        
        
        function t = get.thisfunc(obj)
            t = class(obj);
            t = str2func(t);
        end
    end
    
end