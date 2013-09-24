function [ dist ] = W_dist( X1, X2, W )
%W_DIST Summary of this function goes here
%   Detailed explanation goes here

d1 = diag((X1 * W) * X1') * ones(1, size(X2, 1));
d2 = ones(size(X1, 1), 1) * diag((X2 * W) * X2')';
d3 = X1 * W * X2';
% dist = sqrt(d1 + d2 - 2*d3);
dist = sqrt(max(0, d1 + d2 - 2*d3));

end