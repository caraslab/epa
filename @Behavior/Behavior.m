classdef Behavior < epa.DataInterface
    
    properties
        Sex
        Condition
        DOB
        Notes
        Date
        Reward
        
        ID
        
        Bits     

        Events   (1,:) epa.Event    % An array of Event objects        
    end

    properties (Dependent)
        EventNames
    end
    
    methods
        function obj = Behavior(varargin)
            
        end




        function ind = get_Code(obj,code)
            rc = obj.find_Event("ResponseCode").Values;
            fn = fieldnames(obj.Bits);

            if nargin < 2 || isempty(code)
                code = fieldnames(obj.Bits);
            end
            code = string(code);
            fn   = string(fn);
            assert(all(ismember(code,fn)),'Invalid Code')

            for i = 1:length(code)
                ind.(code{i}) = bitget(rc,obj.Bits.(code{i}));
            end
        end


        function add_EventData(obj,Data)
            fn = fieldnames(Data);
            for i = 1:length(fn)
                obj.add_Event(fn{i},[Data.(fn{i})]);
            end
        end


        function n = get.EventNames(obj)
            n = [obj.Events.Name];
        end

        function add_Event(obj,name,values)
            if nargin < 3, values = []; end

            existingEvents = obj.EventNames;
            
            if ~isempty(existingEvents) && any(ismember(existingEvents,name))
                fprintf(2,'Event "%s" already eaxists for this Session object\n',en)
                return
            end
            
            obj.Events(end+1) = epa.Event(obj,name,[],values);
        end

        
        function e = find_Event(obj,name)
            e = [];
            if isempty(name), return ;end
            name = string(name);
            if numel(obj) > 1
                e = arrayfun(@(a) a.find_Event(name),obj,'uni',0);
                return
            end
            e = obj.Events(strcmpi([obj.Events.Name],name));
        end
    end
    
end