function [avgStrm,elec] = mean_by_electrode_group(SessionObj,varargin)


par.electrode = 1;
par.groups = [];

if nargin > 1 && isequal(varargin{1},'getdefaults'), avgStrm = par; return; end

par = epa.helper.parse_params(par,varargin{:});


Strm = SessionObj.get_streams_by_Electrode(par.electrode);

E = SessionObj.Electrodes(Strm(1).ElectrodeIndex);

g = E.Group;

ug = unique(g);

avgStrm(size(ug)) = epa.Stream;
for i = 1:length(ug)
    ind = g == ug(i);
    avgStrm(i).Data = mean([Strm(ind).Data],2);
end

elec = epa.electrodes.Generic(length(avgStrm));

if nargout == 0, clear avgStrm elec; end
