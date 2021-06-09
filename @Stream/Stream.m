classdef Stream < handle & dynamicprops
    
    
    properties
        Name     string

        Data     (1,:)
        SamplingRate    (1,1) double = 1;
        
        Channel  (1,1) double {mustBeFinite,mustBeInteger} = -1;
        Shank    (1,1) double {mustBePositive,mustBeFinite,mustBeInteger} = 1;
        Coords   (1,3) double {mustBeFinite} = [0 0 0];
        
        Note     (:,1) string   % User notes
        
        TitleStr (1,1) string   % auto generated if empty
    end
    
    
    properties (Dependent)
        SamplingInterval
        N       % number of sampless
    end
    
    properties (SetAccess = protected)
        Time
    end
    
    properties (SetAccess = immutable)
        Session      (1,1) %epa.Session
    end
    
    
    methods
        [t,eidx,vid] = eventlocked(obj,varargin)
        
        function obj = Stream(SessionObj,data)
            obj.Session = SessionObj;
            
            if nargin > 1 && ~isempty(data)
                obj.Data = data;
            end
        end
        
        
        function set.Data(obj,d)
            if ~isempty(d)
                assert(isvector(d),'epa:Stream:Data:InvalidSize', ...
                    'Continous.Data must be a vector');
            end
            obj.Data = d(:)';
            obj.Time = (0:length(d)-1) ./ obj.SamplingRate;
        end
        
        function set.SamplingRate(obj,fs)
            obj.SamplingRate = fs;
            
            obj.Time = (0:obj.N-1) ./ obj.SamplingRate;
        end
        
        function n = get.N(obj)
            n = length(obj.Data);
        end
        
        
        function si = get.SamplingInterval(obj)
            si = 1./obj.SamplingRate;
        end
        
        function set.Time(obj,t)
            assert(length(t) == obj.N,'epa:Stream:set_Time:UnequalSizedVariables', ...
                'Time vector length must equal the length of Data');

            obj.Time = t(:)';
        end
        
        function c = copy(obj)
            if numel(obj) > 1
                c = arrayfun(@copy,obj);
                return
            end
            p = epa.helper.obj2par(obj);
            c = epa.Stream(p.Session);
            p = rmfield(p,'Session');
            epa.helper.par2obj(c,p);
        end
    end % methods (Access = public)
end


