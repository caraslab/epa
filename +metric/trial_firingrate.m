function M = trial_firingrate(trials,varargin)
% M = trial_firingrate(trials,par)
% M = trial_firingrate(trials,'Name',Value,...)
% 
% Compute mean firing rate over an entire window.
% 
% Trial Input:
%   trials  ... [Nx1] cell array with spike times normalized by an event
%               onset. Each cell contains spike times for a single 'trial'.
%               See epa.Cluster.triallocked
%
% Parameter Inputs:
%   window  ... [1x2] analysis window [onset offset], in seconds
%               relative to the trial onset. Default is the minimum to
%               maximum spike time across all trials.
% 
% Outputs:
%   M       ... [Nx1] array of the mean firing rate for each trial within
%               the specified window.
%               
% DJS 2021

par.window = [];

if isequal(trials,'getdefaults'), M = par; return; end

par = epa.helper.parse_params(par,varargin{:});


if isempty(par.window)
    x = cell2mat(trials);
    par.window = [min(x) max(x)];
end

dw = diff(par.window);
M = cellfun(@(a) numel(a)./dw,trials);
