classdef PSTH_Raster < epa.plot.PlotType
    
    
    properties (SetObservable, AbortSet)
        
        event           % event name
        eventvalue     (1,:)
        
        binsize        (1,1) double {mustBeNonempty,mustBePositive,mustBeFinite} = 0.01;
        window         (1,2) double {mustBeNonempty,mustBeFinite} = [0 1];
        normalization  (1,:) char {mustBeNonempty,mustBeMember(normalization,{'count','firingrate','countdensity','probability','cumcount','cdf','pdf'})} = 'count';
        showeventonset (1,1) logical {mustBeNonempty} = true;
        
        
        sortevents     (1,:) char {mustBeMember(sortevents,{'original','events'})} = 'original';
    end
    
    
    properties (SetAccess = private)
        PSTH
        Raster
        parentax
    end
        
    properties (Constant)
        DataFormat = '1D';
        Style = 'PSTH_Raster';
    end
    
    methods
        function obj = PSTH_Raster(Cluster,varargin)
            obj = obj@epa.plot.PlotType(varargin{:});
            if nargin > 0 && ~isempty(Cluster)
                obj.Cluster = Cluster;
            end
        end
        
        function set.window(obj,w)
            if numel(w) == 1, w = sort([0 w]); end
            obj.window = w(:)';
        end
        
       
        
        
        function plot(obj,src,event)
            if nargin > 1 && isempty(obj.handles), return; end % not yet instantiated by calling obj.plot
            
            
            par = epa.helper.obj2par(obj);
            par = rmfield(par,{'Cluster','DataFormat'});
            fn  = fieldnames(par);

            %obj.setup_plot; % do not call here
            if isempty(obj.handles)
                obj.ax = gca;
                
                cla(obj.ax,'reset');
                
                obj.ax.Visible = 'off';
                
                t = tiledlayout(obj.ax.Parent,10,1);
                t.Padding = 'none';
                t.TileSpacing = 'none';
                
                if isa(t.Parent,'matlab.graphics.layout.TiledChartLayout')
                    t.Layout.Tile = obj.ax.Layout.Tile;
                    t.Layout.TileSpan = obj.ax.Layout.TileSpan;
                end
                obj.handles.tiledlayout = t;
            end
            
            
            
            
            
            % Raster
            R = obj.Raster;
            if isempty(R) || isempty(R.ax) || ~ishandle(R.ax) || ~isvalid(R.ax)
                axR = nexttile(obj.handles.tiledlayout);
                axR.Layout.Tile = 1;
                axR.Layout.TileSpan = [2 1];
            else
                axR = R.ax;
            end
            par.ax = axR;
            par.showtitle = true;
            par.showinfo = true;
            parv = struct2cell(par);
            parv = [fn parv]';
            R = epa.plot.Raster(obj.Cluster,parv{:});
            R.plot;
            axR.XAxis.Color = 'none';
            axR.XAxis.Label.String = 'none';
            
            obj.Raster = R;
            
            
            
            
            
            
            % PSTH
            P = obj.PSTH;
            if isempty(P) || isempty(P.ax) || ~ishandle(P.ax) || ~isvalid(P.ax)
                axP = nexttile(t);
                axP.Layout.Tile = 3;
                axP.Layout.TileSpan = [7 1];
            else
                axP = P.ax;
            end
            par.ax = axP;
            par.showtitle = false;
            par.showinfo = false;
            parv = struct2cell(par);
            parv = [fn parv]';
            P = epa.plot.PSTH(obj.Cluster,parv{:});
            P.plot;
            axP.Color = 'none';
            
            obj.PSTH = P;
            
            t.Toolbar = axtoolbar;
            
            epa.helper.setfont(obj.ax);
            
            linkaxes([axR axP],'x');
            
            obj.handles.Raster = R.handles;
            obj.handles.PSTH   = P.handles;
            
        end
        
    end
    
end