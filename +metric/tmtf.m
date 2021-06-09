function M = tmtf(trials,par)
% M = tmtf(trials,par)

if ~isfield(par,'binsize') || isempty(par.binsize)
    par.binsize = 0.01;
end


Fs = 1./par.binsize;

tvec = par.window(1):par.binsize:par.window(2)-par.binsize;

h = cellfun(@(a) histcounts(a,tvec,'Normalization','countdensity'),trials,'uni',0);
h = cell2mat(h)';

L = 2^nextpow2(size(h,1));
Y = fft(h,L,1);
P2 = abs(Y./L);
P1 = P2(1:round(L/2)+1,:);
P1(2:end-1,:) = 2*P1(2:end-1,:);
f = Fs*(0:round(L/2))/L;


[~,i] = min((f - par.modfreq).^2);
M = mean(P1(i,:),1);

end

