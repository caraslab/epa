function S = kilosort2session(DataPath)
% S = kilosort2session(DataPath)
% 
% ex:   DataPath = 'C:\Path\To\Sorted\Data\';
%       S = epa.kilosort2session(DataPath);
% 
% Returns an array of Session object (S) derived from the DataPath, where
% DataPath is an array with one or more strings (or cell array of strings)
% pointing to the root directory of the Kilosort data output.
% 
% Important note: This function looks for files located under DataPath that
% have similar names. These names are derived from the first column within
% the '*concat_breakpoints.csv' file.
% 
% Expected files at the DataPath location:
%   config.mat 
%       > expected to have a structure variable called 'ops'
%   *concat_breakpoints.csv
%   *concat_cluster*.txt
%       > searched for exhaustively through all subdirectories
%   *trialInfo.csv
%       > searched for exhaustively through all subdirectories
% 
% Note that the asterisk, '*', is a wildcard that can stand for any string.
% 
% 
% DJS 2021

fprintf(2,'WARNING: kilosort2session will soon be removed.\nPlease use epa.load.kilosort instead.\n')

S = epa.load.kilosort(DataPath);

