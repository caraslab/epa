classdef Cluster < handle & dynamicprops
    % C = epa.Cluster(SessionObj,[ID],[Spiketimes],[SpikeWaveforms])
    
    
    properties
        ID       (1,1) uint16 {mustBeFinite} = -1;
        Name     string
        Type     string {mustBeMember(Type,["SU","MSU","MU","Noise",""])} = ""

        SpikeTimes (:,1) double {mustBeFinite}
        Waveforms  single
        
        Channel  (1,1) double {mustBeFinite,mustBeInteger} = -1;
        Shank    (1,1) double {mustBePositive,mustBeFinite,mustBeInteger} = 1;
        Coords   (1,3) double {mustBeFinite} = [0 0 0];
        
        UserData 
        
        Note     (:,1) string   % User notes
        
        TitleStr (1,1) string   % auto generated if empty
    end
    
    
    properties (Dependent)
        SamplingRate   % same as obj.Session.SamplingRate
        SpikeSamples   % array of spike samples
        N              % spike count
    end
    
    properties (SetAccess = immutable)
        Session      (1,1) %epa.Session
    end
    
    
    methods
        [t,eidx,vid]    = eventlocked(obj,varargin)
        [trials,V,eidx] = triallocked(obj,varargin)
        [c,b,v]         = psth(obj,varargin)
        [dprime,vals,M,V] = neurometric_dprime(obj,varargin)
        [n,lags]        = interspike_interval(obj,varargin)
        [r,lags]        = xcorr(obj,varargin)
        
        function obj = Cluster(SessionObj,ID,SpikeTimes,SpikeWaveforms)
            
            if nargin >= 1 && ~isempty(SessionObj), obj.Session = SessionObj; end
            if nargin >= 2 && ~isempty(ID), obj.ID = ID; end
            
            
            if nargin == 3
                obj.SpikeTimes = SpikeTimes;
                
            elseif nargin == 4
                obj.Waveforms = SpikeWaveforms;
            end
        end
        
        function t = get.SpikeSamples(obj)
            t = round(obj.SpikeTimes .* obj.SamplingRate);
        end
        
        
        function n = get.N(obj)
            n = length(obj.SpikeTimes);
        end
        
        function fs = get.SamplingRate(obj)
            fs = obj.Session.SamplingRate;
        end
        
        function tstr = get.TitleStr(obj)
            if obj.TitleStr == ""
                tstr = sprintf('%s-%d[%d]',obj.Type,obj.ID,obj.N);
                if obj.Name ~= ""
                    tstr = sprintf('%s-%s',obj.Name,tstr);
                end
            else
                tstr = obj.TitleStr;
            end
        end
        
        function c = copy(obj)
            if numel(obj) > 1
                c = arrayfun(@copy,obj);
                return
            end
            p = epa.helper.obj2par(obj);
            c = epa.Cluster(p.Session);
            p = rmfield(p,'Session');
            epa.helper.par2obj(c,p);
        end
    end
end
                
                
