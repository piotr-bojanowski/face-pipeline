% MRE_GAUSSIAN_DERIV_FILTER   Gaussian derivative filter
%   [DX,DY] = mre_gaussian_deriv_filter(I,sigma,varargin) computes the
%   convolution of I with X and Y Gaussian derivatives of given sigma
%   (equivalent Gaussian has unit integral). Additional
%   arguments are passed to imfilter() e.g. boundary settings.

function [DX,DY] = mre_gaussian_deriv_filter(I,sigma,varargin)

kw=ceil(3*sigma);
x=-kw:kw;
kg=exp(-x.*x/(2*sigma^2))/sqrt(2*pi*sigma^2);
kd=kg.*x;
DX=imfilter(imfilter(I,kg',varargin{:}),kd,varargin{:});
DY=imfilter(imfilter(I,kg,varargin{:}),kd',varargin{:});
