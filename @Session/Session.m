classdef Session < handle
    
    properties
        Clusters (1,:) epa.Cluster  % An array of Cluster objects
        Streams  (1,:) epa.Stream   % An array of Stream objects
        Events   (1,:) epa.Event    % An array of Event objects
        Electrodes  % one or more Electrode objects (i.e, class that inherits from the abstract class epa.electrodes.Electrode)
                    % Note: user must subsequently set ElectrodeIndex in
                    % obj.Clusters and/or obj.Streams using
                    % set(obj.Clusters,'ElectrodeIndex',1) .. or whatever
                    % is the appropriate electrode index.
        
        Name     (1,1) string       % Session name
        Date     (1,1) string       % Session date
        Time     (1,1) string       % Session start time
        
        Subject   (1,1) string
        Scientist (1,1) string
        
        SamplingRate  (1,1) double {mustBePositive,mustBeFinite}  = 1; % Acquisition sampling rate (Hz)

        
        
        Notes     (:,1) string      % User notes
        
        UserData    % whatever you want
    end
    
    properties (Dependent)
        EventNames
        StreamNames
        NClusters
        NEvents
        NStreams
        DistinctEventValues
        Summary
    end
    
    methods
        add_TDTStreams(obj,TDTTankPath,varargin)
        add_TDTEvents(obj,TDTTankPath,excludeEvents)
        [data,cfg] = session2fieldtrip(obj,varargin);
        
        function obj = Session(SamplingRate,Clusters,Events)
            epa.helper.add_paths;
            
            if nargin >= 1 && ~isempty(SamplingRate),      obj.SamplingRate = SamplingRate; end
            if nargin >= 2 && isa(Clusters,'epa.Cluster'), obj.Clusters = Clusters; end
            if nargin >= 3 && isa(Events,'epa.Event'),     obj.Events = Events; end
        end
        
        
        function add_Event(obj,varargin)
            
            existingEvents = obj.EventNames;
            
            if isa(varargin{1},'epa.Event')
                en = varargin{1}.Name;
            else
                en = varargin{1};
            end
            
            if ~isempty(existingEvents) && any(ismember(existingEvents,en))
                fprintf(2,'Event "%s" already eaxists for this Session object\n',en)
                return
            end
            
            obj.Events(end+1) = epa.Event(obj,varargin{:});
        end
        
        function add_Cluster(obj,varargin)
            if isempty(obj.Clusters)
                existingIDs = [];
            else
                existingIDs = [obj.Clusters.ID];
            end
            
            if isa(varargin{1},'epa.Cluster')
                cid = varargin{1}.ID;
            else
                cid = varargin{1};
            end
            
            assert(~ismember(cid,existingIDs),'epa:Session:add_Cluster:IDexists', ...
                'Cluster %s already exists for this Session object\n',cid)            
            
            obj.Clusters(end+1) = epa.Cluster(obj,varargin{:});
        end
        
        function add_Stream(obj,varargin)
            obj.Streams(end+1) = epa.Stream(obj,varargin{:});
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
        
        
        function remove_Stream(obj,name)
            name = string(name);
            for i = 1:length(obj)
                ind = strcmpi([obj(i).Streams.Name],name);
                obj(i).Streams(ind) = [];
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
        
        function e = f_E(obj,name)
            e = obj.find_Event(name);
        end
        
        function c = find_Cluster(obj,name)
            name = string(name);
            if numel(obj) > 1
                c = arrayfun(@(a) a.find_Cluster(name),obj);
                return
            end
            cnames = [obj.Clusters.Name];
            try
                c = arrayfun(@(a) obj.Clusters(strcmpi(cnames,a)),name);
            catch
                c = nan;
            end
        end
        
        function c = f_C(obj,name)
            c = obj.find_Cluster(name);
        end
        
        function s = find_Stream(obj,name)
            name = string(name);
            if numel(obj) > 1
                s = arrayfun(@(a) a.find_Stream(name),obj,'uni',0);
                return
            end
            snames = [obj.Streams.Name];
            
            ind = snames == name;
            s = obj.Streams(ind);
        end
      
        function s = f_S(obj,name)
            s = obj.find_Stream(name);
        end
        
        function s = find_Session(obj,name)
            name = cellstr(name);
            s = obj(contains(cellstr([obj.Name]),name));
        end
        
        
        
        
        
        
        
        
        
        function c = common_Clusters(obj)
            C = [obj.Clusters];
            [~,ia,ib] = unique([C.Name]);
            ind = arrayfun(@(x) sum(x == ib),ia) == numel(obj);
            c = C(ia(ind));
        end
        
        function s = common_Streams(obj)
            S = [obj.Streams];
            [~,ia,ib] = unique([S.TitleStr]);
            ind = arrayfun(@(x) sum(x == ib),ia) == numel(obj);
            s = S(ia(ind));
        end
        
        function e = common_Events(obj)
            E = [obj.Events];
            [~,ia,ib] = unique([E.Name]);
            ind = arrayfun(@(x) sum(x == ib),ia) == numel(obj);
            e = E(ia(ind));
        end
        
        
        
        function s = get_streams_by_Electrode(obj,e)
            if isstring(e) || ischar(e)
                e = char(e);
                ind = arrayfun(@(a) isa(a,['epa.electrodes.' e]),obj.Electrodes);
                e = find(ind);
            elseif ~isnumeric(e)
                ind = arrayfun(@(a) isa(a,class(e)),obj.Electrodes);
                e = find(ind);
            end
            i = [obj.Streams.ElectrodeIndex];
            s = obj.Streams(ismember(i,e));
        end
                
        function s = get_clusters_by_Electrode(obj,e)
            if isstring(e) || ischar(e)
                e = char(e);
                ind = arrayfun(@(a) isa(a,['epa.electrodes.' e]),obj.Electrodes);
                e = find(ind);
            elseif ~isnumeric(e)
                ind = arrayfun(@(a) isa(a,class(e)),obj.Electrodes);
                e = find(ind);
            end
            i = [obj.Clusters.ElectrodeIndex];
            s = obj.Clusters(ismember(i,e));
        end
        
        
        
        function v = get.DistinctEventValues(obj)
            v = arrayfun(@(a) a.DistinctValues,obj.Events,'uni',0);
        end
        
        function n = get.StreamNames(obj)
            n = unique([obj.Streams.Name]);
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
        
        function n = get.NStreams(obj)
            n = numel(obj.StreamNames);
        end
        
        function s = get.Summary(obj)
            s{1,1} = char(obj.Name);
            s{2,1} = sprintf('Date: %s',obj.Date);
            s{3} = sprintf('Time: %s',obj.Time);
            s{4} = sprintf('Research: %s',obj.Scientist);
            s{5} = sprintf('Sampling Rate: %.5f Hz',obj.SamplingRate);
            s{6} = sprintf('%d Events',obj.NEvents);
            s{7} = sprintf('%d Clusters',obj.NClusters);
            s{8} = sprintf('%d Streams',obj.NStreams);
        end
        
        
        
        function s = copy(obj)
            if numel(obj) > 1
                s = arrayfun(@copy,obj);
                return
            end
           
            s = epa.Session;
            p = epa.helper.obj2par(obj);
            epa.helper.par2obj(s,p);
            
            if ~isempty(obj.Streams)
                s.Streams  = arrayfun(@copy,obj.Streams);
            end
            
            if ~isempty(obj.Clusters)
                s.Clusters = arrayfun(@copy,obj.Clusters);
            end
            
            if ~isempty(obj.Events)
                s.Events   = arrayfun(@copy,obj.Events);
            end
            
        end

        function data = export_fieldtrip_data(obj,streamName)
            if nargin < 2 || isempty(streamName), streamName = obj.StreamNames(1); end

            S = obj.find_Stream(streamName);

            data.trial   = {[S.Data]'};
            data.fsample = S(1).SamplingRate;
            data.time    = {(0:size(data.trial{1},2)-1) ./ data.fsample};
            data.label   = cellfun(@char,{S.TitleStr},'uni',0);
            data.sampleinfo = [1 length(data.time{1})];
        end
        
    end % methods (Access = public)
    
    
end