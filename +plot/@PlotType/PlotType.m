classdef (Abstract) PlotType < handle & dynamicprops
    
    properties (Abstract,Constant)
        DataFormat
        Style
    end
    
    methods (Abstract)
        plot(obj,src,event)
    end
    
    
    
    
    properties (SetObservable,AbortSet)
        Cluster         (1,1) %epa.Cluster
        colormap = [];
        
        showtitle       (1,1) logical = true
        title
        titlefontsize   (1,1) double {mustBePositive,mustBeFinite,mustBeNonempty} = 8;
        
        showinfo        (1,1) logical = true
        info
        infofontsize    (1,1) double {mustBePositive,mustBeFinite,mustBeNonempty} = 8;
        
        showlegend      (1,1) logical {mustBeNonempty} = false
        
        event           (1,1) %epa.Event
        eventvalue      (1,:)
        
        includeallevents   (1,1) logical = false
    end
    
    properties
        listenforchanges (1,1) logical = true
    end
    
    
    properties (Transient) % immutable???
        ax
    end
    
    properties (Access = protected,Hidden,Transient)
        els
    end
    
    properties (SetAccess = protected,Transient)
        handles
    end
    
    
    methods
        function obj = PlotType(varargin)
            par = epa.helper.parse_params(obj,varargin{:});
            
            epa.helper.par2obj(obj,par);
            
            obj.els = epa.helper.listen_for_props(obj,@obj.plot);
        end
        
        
        function set.listenforchanges(obj,tf)
            obj.listenforchanges = tf;
            obj.els.Enabled = tf;
        end
        
        function show_infotext(obj)
            str = char(obj.ax.Title.String);
            obj.ax.Title.String = {[str ' ' obj.info]};
            obj.ax.Title.HorizontalAlignment = 'left';
            obj.ax.Title.Position(1) = obj.ax.XLim(1);
            obj.ax.Title.FontName = 'Consolas';
            obj.ax.Title.FontSize = obj.titlefontsize;
%             obj.ax.TitleFontSizeMultiplier = .8;
        end
        
        
        function evnt = get.event(obj)
            if ~isa(obj.event,'epa.Event') && isa(obj.Cluster,'epa.Cluster')
                obj.event = obj.Cluster.Session.find_Event(obj.event);
            end
            evnt = obj.event;
        end
        
        function s = get.info(obj)
            if isequal(obj.Cluster,0)
                s = {''};
            else
                s = char(obj.Cluster.TitleStr);
            end
        end
        
        function axes_destroyed(obj,src,event)
            delete(obj.els);
        end
        
        
        function show_title(obj,str)
            if nargin < 2 || isempty(str) 
                obj.ax.Title.String = obj.title;
            else
                obj.ax.Title.String = str;
            end
            obj.ax.Title.HorizontalAlignment = 'left';
            obj.ax.Title.Position(1) = obj.ax.XLim(1);
            obj.ax.Title.FontName = 'Consolas';
            obj.ax.Title.FontSize = obj.titlefontsize;
%             obj.ax.TitleFontSizeMultiplier = .8;
        end
        
        
        function s = get.title(obj)
            if isequal(obj.Cluster,0)
                s = {};
            else
                s = {obj.Cluster.Session.Name};
            end
        end
        
        function standard_plot_postamble(obj)
            obj.ax.Title.String = {};
            if obj.showtitle, obj.show_title; end
            if obj.showinfo, obj.show_infotext; end
            if obj.showlegend, obj.handles.legend = legend([obj.handles.plot]); end

            % Calling drawnow here really slows things down, but seems to
            % be required to get the titles to display correctly
            drawnow limitrate
            
            epa.helper.setfont(obj.ax);

            obj.ax.Color = 'none';
            obj.ax.Title.Units = 'normalized';
        end
        
        
        
        function par = saveobj(obj)
            par = epa.helper.obj2par(obj);
            
            % dump any transient properties
            m = metaclass(obj);
            p = m.PropertyList;
            p(~[p.Transient]) = [];
            p = {p.Name};
            idx = find(ismember(p,fieldnames(par)));
            for i = 1:length(idx)
                par.(p{idx(i)}) = [];
            end
        end
        
        
    end % methods (Access = public)
      
    methods (Access = protected)
        
        function setup_plot(obj)
            if isempty(obj.ax) || ~ishandle(obj.ax) || ~isvalid(obj.ax)
                obj.ax = gca; 
            end
            % not sure why, but ax.DeleteFcn is not being called when the
            % axes object is destroyed ????????
            obj.ax.DeleteFcn = @obj.axes_destroyed;
        end
    end % methods (Access = protected)
    
    methods (Static)
        function obj = loadobj(par)
            obj = epa.plot.(par.Style)(par.Cluster,par);
        end
    end
end