classdef Session < handle
    
    properties
        Clusters (1,:) epa.Cluster  % An array of Cluster objects
        Streams  (1,:) epa.Stream   % An array of Stream objects
        Events   (1,:) epa.Event    % An array of Event objects
        
        Name     (1,1) string       % Session name
        Date     (1,1) string       % Session date
        Time     (1,1) string       % Session start time
        
        Researcher (1,1) string
        
        SamplingRate  (1,1) double {mustBePositive,mustBeFinite}  = 1; % Acquisition sampling rate (Hz)

        Notes     (:,1) string      % User notes
        
        UserData    % whatever you want
    end
    
    properties (Dependent)
        EventNames
        NClusters
        NEvents
        DistinctEventValues
        Summary
    end
    
    methods
        add_TDTStreams(obj,TDTTankPath)
        add_TDTEvents(obj,TDTTankPath)
        
        function obj = Session(SamplingRate,Clusters,Events)
            addpath(fullfile(epa.helper.rootdir,'+epa','metrics'));
            addpath(fullfile(epa.helper.rootdir,'+epa','Examples'));
            
            
            if nargin >= 1 && ~isempty(SamplingRate), obj.SamplingRate = SamplingRate; end
            if nargin >= 2 && isa(Clusters,'epa.Cluster'), obj.Clusters = Clusters; end
            if nargin >= 3 && isa(Events,'epa.Event'), obj.Events = Events; end
        end
        
        function add_Event(obj,varargin)
            
            existingEvents = obj.EventNames;
            
            if isa(varargin{1},'epa.Event')
                en = varargin{1}.Name;
            else
                en = varargin{1};
            end
            
            if any(ismember(existingEvents,en))
                fprintf(2,'Event "%s" already eaxists for this Session object\n',en)
                return
            end
            
            obj.Events(end+1) = epa.Event(obj,varargin{:});
        end
        
        function add_Cluster(obj,varargin)
            existingIDs = [obj.Clusters.ID];
            
            if isa(varargin{1},'epa.Cluster')
                cid = varargin{1}.ID;
            else
                cid = varargin{1};
            end
            
            assert(~ismember(cid,existingIDs),'epa:Session:add_Cluster:IDexists', ...
                'Cluster %s already exists for this Session object\n',cid)            
            
            obj.Clusters(end+1) = epa.Cluster(obj,varargin{:});
        end
        
       
        
        
        
        function remove_Event(obj,name)
            name = string(name);
            for i = 1:length(obj)
                ind = strcmpi([obj(i).Events.Name],name);
                obj(i).Events(ind) = [];
            end
        end
        
        function remove_Cluster(obj,name)
            name = string(name);
            for i = 1:length(obj)
                ind = strcmpi([obj(i).Clusters.Name],name);
                obj(i).Clusters(ind) = [];
            end
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
        
        function c = find_Cluster(obj,name)
            name = string(name);
            if numel(obj) > 1
                c = arrayfun(@(a) a.find_Cluster(name),obj,'uni',0);
                return
            end
            c = obj.Clusters(strcmpi([obj.Clusters.Name],name));
        end
        
        function s = find_Session(obj,name)
            name = cellstr(name);
            s = obj(contains(cellstr([obj.Name]),name));
        end
        
        
        
        
        
        
        
        
        
        function c = common_Clusters(obj)
            C = [obj.Clusters];
            [~,ia,ib] = unique([C.Name]);
            
            s = arrayfun(@(x) sum(x == ib),ia);
            ind = s == length(obj);
            
            c = C(ia(ind));
        end
        
        
        function c = common_Events(obj)
            E = [obj.Events];
            [~,ia,ib] = unique([E.Name]);
            
            s = arrayfun(@(x) sum(x == ib),ia);
            ind = s == length(obj);
            
            c = E(ia(ind));
        end
        
        
        
        
        
        
        
        
        function v = get.DistinctEventValues(obj)
            v = arrayfun(@(a) a.DistinctValues,obj.Events,'uni',0);
        end
        
        function n = get.EventNames(obj)
            n = [obj.Events.Name];
        end
        
        function n = get.NClusters(obj)
            n = numel(obj.Clusters);
        end
        
        function n = get.NEvents(obj)
            n = numel(obj.Events);
        end
        
        function s = get.Summary(obj)
            s{1,1} = obj.Name;
            s{2,1} = sprintf('Date: %s',obj.Date);
            s{3} = sprintf('Time: %s',obj.Time);
            s{4} = sprintf('Research: %s',obj.Researcher);
            s{5} = sprintf('Sampling Rate: %.5f Hz',obj.SamplingRate);
            s{6} = sprintf('%d Events',obj.NEvents);
            s{7} = sprintf('%d Clusters',obj.NClusters);
        end
        
        
        
        
    end
    
end