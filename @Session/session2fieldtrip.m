function data = session2fieldtrip(S,varargin)
% data = session2fieldtrip(S)
% 
% Convert Session object with Stream data for use with the Fieldtrip
% toolbox.
% 
% Options:
%   event       ... an event name or epa.Event object (default = none, i.e
%                   return continuous data)
%   channels    ... Determines which channels to return (default = [], i.e.
%                   return all channels in data)
%   window      ... Specify window [1x2] around event onsets. Can also
%                   specify [Nx2] onset, offset pairs for specifying
%                   windows on a trial-by-trial basis. Default is
%                   determined by the minimum difference between onsets.
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
par.window = [];

if nargin > 1 && isequal(varargin{1},'getdefaults'), data = par; return; end

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
    
    ons = event.OnOffTimes(:,1);
    
    if isempty(par.window)
        md = min(diff(event.OnOffTimes,1,2));
        par.window = [0 md-1./Fs];
    end

    cfg.trl(:,1) = ons+par.window(:,1); % trial start
    cfg.trl(:,2) = ons+par.window(:,2); % trial end
    cfg.trl(:,3) = par.window(:,1);     % trigger offset re trial start
    
    cfg.trl = round(Fs.*cfg.trl); % seconds -> samples re recording start
    
    data = ft_redefinetrial(cfg,data);
    
    data.trialinfo = event.Values;
end
                