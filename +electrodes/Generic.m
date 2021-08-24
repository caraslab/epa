classdef Generic < epa.electrodes.Electrode
   
    properties
        
    end
    
    properties (SetAccess = immutable)
        N = 64;
    end
    
    methods
        function obj = Generic(N)
            if nargin < 1 || isempty(N), N = 64; end
            obj.N = N;
            obj.Style = "chronic";
            obj.Manufacturer = "Generic";
            obj.Model = "Generic";
            
            obj.Units = 'μm';
            
            [x,y] = meshgrid(1:sqrt(obj.N),1:sqrt(obj.N));
            obj.Coordinates = [x(:) y(:)];
                                    
            obj.set_neighbors;
        end
    end
end