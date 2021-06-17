function  M = cl_calcpower(trials,par)


%
%This function performs an FFT on spike vectors pulled from the stimdata
%input variable, which contains discrete spike times. FFTs are calculated
%for a single data trial at a time.
%The function calls mtspectrumpt.m, which is part of the
%chronux data analysis package. 
%
%Powermat =  [stimulus, ave power, std power, sem power]
%
%ML Caras Dec 2015



%-------------------------------------------------------------------
%Initialize parameters for power analysis

par.tapers = [5 9]; %[TW K] where TW = time-bandwidth product and K =
%the number of tapers to be used (<= 2TW-1). [5 9]
%are the values used by Rosen, Semple and Sanes (2010) J Neurosci.


par.pad = 3; %Padding for the FFT. -1 corresponds to no padding,
%0 corresponds to the next higher power of 2 and so
%on. This value will not affect the result
%calculation, however, using a value of 1 improves
%the efficiancy of the function and increases the
%number of frequency bins of the result.


% par.fpass = [0 10]; %[fmin fmax]
par.fpass = par.modfreq .* 2 .^([-1 1]);
%Frequency band to be used in calculation.

% par.Fs = fs;        %Sampling rate

par.err = [1 .05];  %Theoretical errorbars (p = 0.05). For Jacknknife
%errorbars use [2 p]. For no errorbars use [0 p].

par.trialave = 0;   %If 1, average over trials or channels.

fscorr = 1;            %If 1, use finite size corrections.

%-------------------------------------------------------------------
M = nan(size(trials));
for i = 1:length(trials)
    fprintf('Trial %d of %d ...',i,length(trials))
    
    if numel(trials{i})<2
        fprintf(2,' too few spikes, skipping\n')
        continue
    end
    
    if numel(trials{i}) < 3
        par.pad = 6;
    else
        par.pad = 3;
    end
    
    %Calculate the power across frequencies
    [spectra,f] = mtspectrumpt(trials{i},par,fscorr); 
    
    %Find the index value closest to MF
    [~,idx] = min(abs(f-par.modfreq));
    
    M(i) = spectra(idx);
    
    fprintf(' done\n')
end




