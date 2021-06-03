classdef Spike < handle
    
    properties
        Waveform    (1,:) single = nan
        Sample      (1,1) uint32 {mustBeNonnegative,mustBeFinite}
    end
    
    methods
        function obj = Spike(Sample,Waveform)
            narginchk(1,2)
            
            if nargin < 2 || isempty(Waveform), Waveform = nan; end
            
            obj.Sample = Sample;
            obj.Waveform = Waveform;
        end
        
        function h = plot(obj,ax)
            if nargin < 2 || isempty(ax), ax = gca; end
            
            h = plot(ax,obj.Waveform,'-k','linewidth',2);
        end
        
    end
    
end