function [frames,D] = get_sift_desc( J , P , s , VP )
%GET_SIFT_DESC Summary of this function goes here
%   Detailed explanation goes here


% converting to grayscale
if ndims(J)==3
    J = rgb2gray(J);
end
J = single(J);


% Adding virtual points
nVP = length(VP);
P0  = zeros(2, nVP);
for i = 1 : nVP
    P0( : , i) = mean(P( : , VP{i}), 2);
end

frames = [];
% specifying two scales for the sift descriptors
for i = 1:length(s)
    frames  = cat(2, frames, [P0 ; s(i)*ones(1,nVP) ; zeros(1,nVP)]);
end

% extracting sifts
[~,D]   = vl_sift(J,'frames',frames);

D = double(D);
D = bsxfun(@times, D, 1 ./ sqrt(sum(D .^ 2)));

end

