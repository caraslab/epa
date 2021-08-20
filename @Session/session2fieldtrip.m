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
par.trialwindow = [-.25 1];

if isequal(varargin{1},'getdefaults'), data = par; return; end

par = epa.helper.parse_params(par,varargin{:});

Strm = S.Streams(par.channels);

data.label   = cellfun(@(a) num2str(a,'CH%02d'),num2cell(par.channels),'uni',0)';
data.fsample = Strm(1).SamplingRate;

if isempty(par.event) % represent data as one long trial
    
    data.trial      = {[Strm.Data]'};
    data.time       = {(0:Strm(1).N-1)./data.fsample};
    data.sampleinfo = [1 Strm(par.channels(1)).N];

else
    
    event = par.event;
    if isstring(event) || ischar(event)
        event = S.find_Event(event);
    end
    
    data.trialinfo = event.Values;
    
    if numel(par.trialwindow) == 2 % otherwise, user specified a time window for each trial
        par.trialwindow = repmat(par.trialwindow,event.N,1);
    end

    trons = event.OnOffTimes(:,1);
    sData = [Strm.Data]';
    for i = 1:event.N
        tvecs = par.trialwindow(i,1):Strm(1).SamplingInterval:par.trialwindow(i,2);
        ind = Strm(1).Time >= trons(i)+par.trialwindow(1) & Strm(1).Time <= trons(i)-par.trialwindow(2);
        data.trial{1,i} = sData(:,ind);
        data.time{1,i}  = trons(i) + tvecs;
        data.sampleinfo(i,:) = [find(ind,1) find(ind,1,'last')];
    end
    data.trialinfo = event.Values;
end
                