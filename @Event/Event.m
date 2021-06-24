classdef Event < handle
    
    properties
        Name          (1,1) string = "Unnamed Event"
        OnOffTimes    (:,2) single {mustBeNonnegative} % time when the event [started ended]

        SamplingRate  (1,1) single = -1 % takes value of Session.SamplingRate unless specified
        Values           % Some associated value for the event (ex stimulus frequency or sound level)
        Units         string % Units associated with the Values (ex "Hz" for frequency)        
    end

    properties (SetObservable = true)
        ValidTrials     (:,1) logical = true
    end
    
    properties (Dependent)
        OnOffSamples
        DistinctValues
        N
    end
    
    
    properties (SetAccess = immutable)
        Session      (1,1) %epa.Session
    end
    
    methods
        function obj = Event(SessionObj,Name,OnOffTimes,Values,Units)
            narginchk(3,5)
            
            obj.Session = SessionObj;
            obj.Name = Name;
            obj.OnOffTimes = OnOffTimes;
           
            
            
            if nargin < 4 || isempty(Values), Values = nan; end
            if nargin < 5 || isempty(Units), Units = "";  end
            
            obj.Values = Values;
            obj.Units = Units;
        end
        
        
        function set.ValidTrials(obj,ivt)
            assert(length(ivt) == obj.N, ...
                'epa:Event:ValidTrials:UnequalLength', ...
                'When specifying ValidTrials, the length must equal the number events (obj.N)')
            
            obj.ValidTrials = ivt(:);
        end
        
        function vt = get.ValidTrials(obj)
            if isempty(obj.ValidTrials)
                obj.ValidTrials = true(obj.N,1);
            end
            vt = obj.ValidTrials;
        end
        
        function n = get.N(obj)
            n = size(obj.OnOffSamples,1);
        end
        
        function fs = get.SamplingRate(obj)
            if obj.SamplingRate <= 0
                obj.SamplingRate = obj.Session.SamplingRate;
            end
            fs = obj.SamplingRate;
        end
        
        
        
        
        function s = get.OnOffSamples(obj)
            s = round(obj.OnOffTimes .* obj.SamplingRate);
        end
        
        
        function v = get.DistinctValues(obj)
            v = unique(obj.Values);
        end
        
        
        
        function [v,oot] = subset(obj,val,tol)
            % [v,oo] = subset(obj,val,[tol])
            %
            % returns a subset of Event values and on/off times
            
            if nargin < 3 || isempty(tol), tol = 1e-6; end
            
            v = obj.Values;
            oot = obj.OnOffTimes;
            if nargin >= 2 && ~isempty(val) && ~isequal(val,'all')
                ind = ismembertol(v,val,tol);
                v(~ind) = [];
                oot(~ind,:) = [];
            end
        end
        
        
        
        
        function c = copy(obj)
            if numel(obj) > 1
                c = arrayfun(@copy,obj);
                return
            end
            p = epa.helper.obj2par(obj);
            c = epa.Event(p.Session);
            p = rmfield(p,'Session');
            epa.helper.par2obj(c,p);
        end
    end
end