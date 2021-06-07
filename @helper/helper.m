classdef helper < handle
    methods (Static)
        function tok = tokenize(str,delimiters)
            if nargin < 2 || isempty(delimiters), delimiters = ','; end
            tok = textscan(str,'%s',-1,'delimiter',delimiters);
            tok = tok{1};

%             tok = strsplit(str,delimiters);
        end
        
        function p = get_settable_properties(obj)
            
            M = metaclass(obj);
                        
            p = M.PropertyList;
            ind = ismember({p.SetAccess},'public');
            ind = ind & ~[p.Constant];
            p(~ind) = [];
            p = {p.Name};
                        
            p(ismember(p,{'Cluster','ax','parent','handles', ...
                'DataFormat','event','eventvalue', ...
                'eventx','eventxvalue','eventy','eventyvalue'})) = [];
            
        end
        
        
        function par = parse_params(par,varargin)
            
            if isobject(par)
                par = epa.helper.obj2par(par);
            end
            
            if length(varargin) == 1
                if iscell(varargin) && numel(varargin{1}) == 1
                    varargin = varargin{1};
                end
                
                if iscell(varargin)
                    % might be passed as a varargin, instead of varargin{:}
                    varargin = varargin{:};
                    
                elseif isobject(varargin)
                    varargin = epa.helper.obj2par(varargin);
                    
                end
            end
            
            if isstruct(varargin)
                fn = fieldnames(varargin);
                fv = struct2cell(varargin);
                varargin = [fn'; fv'];
                varargin = varargin(:)';
            end
            
            [~,params] = parseparams(varargin);
            for i = 1:2:length(params)
                par.(lower(params{i})) = params{i+1};
            end
        end
        
        function par = obj2par(obj)
            p = properties(obj);
            for i = 1:length(p)
                par.(p{i}) = obj.(p{i});
            end
        end
        
        function par2obj(obj,par)
            m = metaclass(obj);
            p = m.PropertyList;
            ind = [p.Constant] ...
                | [p.Abstract] ...
                | [p.Dependent] ...
                | ismember({p.SetAccess},{'private','protected'});
            p(ind) = [];
            p = {p.Name};
            fn = fieldnames(par);
            p = intersect(p,fn);
            for i = 1:length(p)
                obj.(p{i}) = par.(p{i});
            end
        end
        
        function els = listen_for_props(obj,callbackFcn)
            m = metaclass(obj);
            p = m.PropertyList;
            p(~[p.SetObservable]) = [];
            p = {p.Name};
            els = addlistener(obj,p,'PostSet',callbackFcn);
        end
        
        function cm = colormap(cm,n)
            
            if isempty(cm)
                if n == 1
                    cm = [0 0 0];
                else
                    cm = @jet;
                end
            end
            
            if ischar(cm)
                cm = str2func(cm);
            end
            
            if isa(cm,'function_handle')
                cm = cm(n);
            elseif size(cm,1) == n
                cm = cm(1:n,:);
            end
        end
        
        function setfont(h)
            fnt = getpref('epa','FontName','Consolas');
            hs = findobj(h,'-property','FontName');
            set(hs,'FontName',fnt);
        end
        
        function t = plot_types
           pt = fullfile(epa.helper.rootdir,'+epa','+plot','@*');
           d = dir(pt);
           d(~[d.isdir]) = [];
           t = {d.name};
           t(ismember(t,'@PlotType')) = [];
           t = cellfun(@(a) a(2:end),t,'uni',0);
        end
        
        function rd = rootdir
            rd = fileparts(fileparts(fileparts(which('epa.helper'))));
        end
        
        function str = metaprop2str(p)
            
            V = p.Validation;
            
            if isempty(V)
                str = {'< unable to get metaproperties >'};
                return
            end
            
            pn = V.Class.Name;
            
            sz = V.Size;
            len = length(sz);
            dim = cell(1:len);
            for k = 1:len
                switch class(sz(k))
                    case 'meta.FixedDimension'
                        dim{k} = sz(k).Length;
                    case 'meta.UnrestrictedDimension'
                        dim{k} = ':';
                end
            end
            dim = cellfun(@num2str,dim,'uni',0);
            dim = strjoin(dim,',');
            
            pv = cellfun(@func2str,V.ValidatorFunctions,'uni',0);
            ind = contains(pv,'mustBeMember');
            if any(ind)
                idx = find(ind);
                for i = 1:length(idx)
                    tpv = strsplit(pv{idx(i)},',');
                    tpv(1) = [];
                    tpv{1}(tpv{1} == '{') = [];
                    tpv{end}(tpv{end} == '}'|tpv{end} == ')') = [];
                    tpv = strjoin(tpv,',');
                    pv{idx(i)} = sprintf('Options: %s',tpv);
                end
            end
            
            str = {};
            if p.HasDefault
                pd = p.DefaultValue;
                str{end+1,1} = sprintf('Default Value = %s',mat2str(pd));
            end
            str{end+1,1} = sprintf('Type: ''%s''',pn);
            str{end+1}   = sprintf('Dimensions: (%s)',dim);
            if ~isempty(pv)
                str{end+1} = 'Validation Rules:';
                str(end+1:end+length(pv)) = pv(:);
            end

        end
    end
end