classdef NeuroNexus_4x16_Poly2_5mm_20s_lin_160 < epa.electrodes.Electrode
   
    properties
        
    end
    
    properties (SetAccess = immutable)
        N = 64;
    end
    
    methods
        function obj = NeuroNexus_4x16_Poly2_5mm_20s_lin_160()
            obj.Style = "chronic";
            obj.Manufacturer = "NeuroNexus";
            obj.Model = "4x16-Poly2-5mm-20s-lin-160";
            
            obj.Units = 'μm';
            obj.PhysicalScaleFactor = 1e6;
            
            obj.Marker = 's';
            
            obj.ChannelMap = (1:64)';
            
            x = [300 300 300 300 300 308.66 308.66 317.32 300 317.32 317.32 317.32 300 317.32 317.32 317.32 150 150 167.32 150 150 150 167.32 150 158.66 150 167.32 158.66 167.32 167.32 167.32 167.32 467.32 467.32 467.32 467.32 467.32 467.32 458.66 458.66 450 450 450 450 450 450 450 17.32 17.32 17.32 17.32 17.32 17.32 8.66 17.32 0 8.66 0 0 0 0 0 0 467.32];
            y = [130 150 170 50 110 570 470 40 90 160 140 120 70 100 80 60 90 70 60 110 150 130 80 170 470 50 100 370 160 40 120 140 60 100 120 140 160 40 570 670 50 170 150 130 110 90 70 80 60 120 100 160 140 270 40 50 370 150 170 110 130 70 90 80];
                
            obj.Coordinates = [x' y'];
            
            obj.MaxNeighborDist = 120;
            
            obj.Group = [3 3 3 3 3 10 9 3 3 3 3 3 3 3 3 3 2 2 2 2 2 2 2 2 8 2 2 7 2 2 2 2 4 4 4 4 4 4 11 12 4 4 4 4 4 4 4 1 1 1 1 1 1 5 1 1 6 1 1 1 1 1 1 4];
            
            obj.Labels = arrayfun(@(a) num2str(a,'CH%03d'),1:64,'uni',0);
            
            obj.ChannelMeasurements = [10*ones(64,1) 16*ones(64,1)];
            
            obj.set_neighbors;
        end
    end
end