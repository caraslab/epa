classdef Stream < epa.DataInterface
    
    properties (SetObservable, AbortSet)
        Data            (:,1)
        SamplingRate    (1,1) double = 1;
        
        Channel  (1,1) double {mustBeFinite,mustBeInteger} = -1;

        Coords   (1,3) double {mustBeFinite} = [0 0 0];
        
        Note     (:,1) string   % User notes
        
        TitleStr (1,1) string   % auto generated if empty
        
        Include  (1,1) logical = true;
    end
    
    
    properties (Dependent)
        SamplingInterval
        N
        Time
    end
    
    
    
    methods
        [t,eidx,vid,swin] = eventlocked(obj,varargin)
        newdata = chunkwiseDeline(obj,freqs,freqrange,chunksize,showOutput)
        
        function obj = Stream(SessionObj,name,channel,data)            
            if nargin >= 1 && ~isempty(SessionObj), obj.Session = SessionObj; end
            if nargin > 1 && ~isempty(name), obj.Name = name; end
            if nargin > 2 && ~isempty(channel), obj.Channel = channel; end
            if nargin > 3 && ~isempty(data), obj.Data = data; end
        end
        
        function set.Data(obj,d)
            obj.Data = d;
        end
        
        function set.SamplingRate(obj,fs)
            obj.SamplingRate = fs;            
        end

        function t = get.Time(obj)
            t = (0:obj.N-1) ./ obj.SamplingRate;
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
        
        
        function s = get.TitleStr(obj)
            if obj.TitleStr == ""
                obj.TitleStr = sprintf('CH%03d',obj.Channel);
            end
            s = obj.TitleStr;
        end
        
    end % methods (Access = public)
end


