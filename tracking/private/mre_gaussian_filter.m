% MRE_GAUSSIAN_FILTER   Gaussian filter
%   J = mre_gaussian_filter(I,sigma,varargin) computes the convolution of I
%   with a 2-D unit integral Gaussian filter of given sigma. Additional
%   arguments are passed to imfilter() e.g. boundary settings.

function J = mre_gaussian_filter(I,sigma,varargin)

if sigma>0
	kw=ceil(3*sigma);
	k=exp(-(-kw:kw).^2/(2*sigma^2));
    k=k/sum(k);
    J=imfilter(imfilter(I,k,varargin{:}),k',varargin{:});
else
    J=I;
end

