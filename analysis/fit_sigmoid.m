function [xfit,yfit,p_val] = fit_sigmoid(x,y,beta0)
% [xfit,yfit,p_val] = fit_sigmoid(x,y,[beta0])
% 
% Adapted from caraslab/ephys-analysis/cl_fitneurometric.m



if nargin < 3 || isempty(beta0)
    %Establish s vector of initial coefficients (beta0)
    beta0 = [0 20 50 5]; 
end


%We will fit our data with a sigmoidal function. To do
%this, we first need to set up the function. The equation
%for a signmoidal function is:
%
%f = y0 + a/(1 + exp(-(x - x0)/b))
%
%The parameters (p) that govern the function are:
%p(1):  y0 = min
%p(2):   a = max - min
%p(3):   b = slope
%p(4):  x0 = x coordinate at inflection point
f = @(p,x) p(1) + p(2) ./ (1 + exp(-(x-p(3))/p(4)));




%Set the maximum number of iterations to 10000
options = statset('MaxIter',10000);

%Estimate the coefficients of a nonlinear regression using
%least squares estimation
p = nlinfit(x,y,f,beta0,options);
xfit = linspace(x(1),x(end),1000);
yfit = f(p,xfit);
yfit_corr = f(p,x);

%Calculate p value to determine if the fit is a valid one
[~, p_val] = corrcoef(y,yfit_corr);
if numel(p_val) > 1
    p_val = p_val(2);
end
