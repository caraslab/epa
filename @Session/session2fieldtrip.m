function data = session2fieldtrip(S,varargin)
% data = session2fieldtrip(S)
% 
% Convert Session object with Stream data for use with the Fieldtrip
% toolbox.
% 
% Output:
%   data.label      % cell-array containing strings, Nchan*1
%   data.fsample    % sampling frequency in Hz, single number
%   data.trial      % cell-array containing a data matrix for each
%                   % trial (1*Ntrial), each data matrix is a Nchan*Nsamples matrix
%   data.time       % cell-array containing a time axis for each
%                   % trial (1*Ntrial), each time axis is a 1*Nsamples vector
%   data.trialinfo  % this field is optional, but can be used to store
%                   % trial-specific information, such as condition numbers,
%                   % reaction times, correct responses etc. The dimensionality
%                   % is Ntrial*M, where M is an arbitrary number of columns.
%   data.sampleinfo % optional array (Ntrial*2) containing the start and end
%                   % sample of each trial
% 
% DJS 2021

par.event = [];
par.channels = 1:length(S.Streams);
par.window = [-.25 1];

if isequal(varargin{1},'getdefaults'), data = par; return; end

par = epa.helper.parse_params(par,varargin{:});

Strm = S.Streams(par.channels);

data.label   = cellfun(@(a) num2str(a,'CH%02d'),num2cell(par.channels),'uni',0)';
data.fsample = Strm(1).SamplingRate;

    
    data.trial      = {[Strm.Data]'};
    data.time       = {(0:Strm(1).N-1)./data.fsample};
    data.sampleinfo = [1 Strm(par.channels(1)).N];

if ~isempty(par.event) % represent data as one long trial

    
    event = par.event;
    if isstring(event) || ischar(event)
        event = S.find_Event(event);
    end
    
    
    Fs = Strm(1).SamplingRate;
    cfg.trl = round(Fs.*([event.OnOffTimes(:,1) event.OnOffTimes(:,1)+par.window(2)]));
    cfg.trl(:,3) = round(Fs.*par.window(1));
    data = ft_redefinetrial(cfg,data);
    
    data.trialinfo = event.Values;
end
                