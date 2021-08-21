classdef NeuroNexus_E32_600_10_100_ECoG < epa.electrodes.Electrode
    
    methods
        
        function obj = NeuroNexus_E32_600_10_100_ECoG()
            obj.Style = "ecog";
            obj.Manufacturer = "NeuroNexus";
            obj.Model = "E32_600_10_100";
            obj.Coordinates = [ ...
                0.6    0.0; ...   % 1
                0.0    0.6; ...   % 2
                0.0    1.2; ...   % 3
                0.0    1.8; ...   % 4
                0.0    2.4; ...   % 5
                1.2    0.0; ...   % 6
                0.6    2.4; ...   % 7
                0.6    1.8; ...   % 8
                0.6    0.6; ...   % 9
                1.2    0.6; ...   % 10
                0.6    1.2; ...   % 11
                0.6    3.0; ...   % 12
                1.2    3.0; ...   % 13
                1.2    2.4; ...   % 14
                1.2    1.8; ...   % 15
                1.2    1.2; ...   % 16
                1.8    1.2; ...   % 17
                1.8    1.8; ...   % 18
                1.8    2.4; ...   % 19
                1.8    3.0; ...   % 20
                2.4    3.0; ...   % 21
                2.4    1.2; ...   % 22
                1.8    0.6; ...   % 23
                2.4    0.6; ...   % 24
                2.4    1.8; ...   % 25
                2.4    2.4; ...   % 26
                1.8    0.0; ...   % 27
                3.0    2.4; ...   % 28
                3.0    1.8; ...   % 29
                3.0    1.2; ...   % 30
                3.0    0.6; ...   % 31
                2.4    0.0];      % 32
            
            obj.ChannelMap = 1:32;
            
            obj.Labels = arrayfun(@(a) num2str(a,'CH%0d'),1:32,'uni',0);
            
            obj.Shank = ones(32,1);
            
            obj.Diameter = 100*ones(32,1);
            
            obj.Marker = 'o';
           
            obj.set_neighbours(0.7);
        end
        
    end
    
end
    
    
    
