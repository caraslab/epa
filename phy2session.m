function S = phy2session(DataPath,varargin)
% S = phy2session(DataPath)
%
% ex:   DataPath = 'C:\Path\To\Sorted\Data\';
%       S = epa.phy2session(DataPath);
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
%       > contains two columns and one header row. the first column
%       contains Session names and the second column contains
%       corresponding sample breakpoints indicating the end of the session.
%   *trialInfo.csv
%       > searched for exhaustively through all subdirectories
%   spike_times.npy    
%       > Vector of cluster spike times (in samples) same length as .spikeClusters
%   spike_clusters.npy
%       > Vector of cluster IDs (Phy nomenclature)   same length as .spikeTimes
%   channel_shanks.npy
%       > Vector of cluster shanks
%   channel_map.npy
%       > Contains channels mapped to electrode. This is important in esp if you got rid of files.
%   cluster_info.tsv
%       > A structure with cluster info 
% 
%   *.dat
%       > Data file contains all samples for all channels
%       > [Channels x Samples] uint64
%       > This file can be specified explicitly. default = '*.dat'
% 
% Note that the asterisk, '*', is a wildcard that can stand for any string.
%
%
% DJS 2021


fprintf(2,'WARNING: phy2session will soon be removed. Please use epa.load.phy instead.\n')

S = epa.load.phy(DataPath);
