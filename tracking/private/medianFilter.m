function [ s ] = medianFilter( s , n )
%MEDIANFILTER Summary of this function goes here
%   Detailed explanation goes here

N = 2*n;
s = [ones(N,1)*s(1); s; ones(N,1)*s(end)];
s = medfilt1(s, n);
s = s(N+1:end-N);


end

