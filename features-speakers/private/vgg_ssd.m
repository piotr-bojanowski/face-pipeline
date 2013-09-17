function s = vgg_ssd(Image, Mask, method)

% VGG_SSD       Sum of squared differences between image and mask
%
%               S = VGG_SSD(Image, Mask, 'ssd') computes 
%               S(x+r2,y+c2) = sum_uv (Image(x+u,y+v) - Mask(u,v))^2
%               where [r2,c2] = floor(size(Mask)/2);
%
%               S = VGG_SSD(Image, Mask, 'nssd') first scales
%               the window graylevels to zero-mean, unit variance.
%               e.g. Mask_normalized = (Mask - mean(Mask(:))) / std(Mask(:))
%                    Image_normalized is analogous.
%
%               Each channel of multiple-channel images is computed separately.
%               Image and Mask must be double (not uint8) currently.


% Author: Andrew Fitzgibbon <awf@robots.ox.ac.uk>
% Date: 30 Jan 02

if nargin < 3
  method = 'ssd';
end

switch method
case 'ssd'
  method_code = 0;
case 'nssd'
  method_code = 1;
otherwise
  error(['vgg_ssd: unknown method [' method ']']);
end

[h,w, channels] = size(Image);
[r,c, channels2] = size(Mask);
r2 = floor(r/2) + 1;
c2 = floor(c/2) + 1;

for k = 1:channels
  s1(:,:,k) = vgg_ssd_aux(Image(:,:,k), Mask(:,:,k), method_code);
end

s = nan * zeros(h,w,channels);
s(r2:h-r+r2, c2:w-c+c2,:) = s1;
%s(r2:h-r2+1, c2:w-c2+1,:) = s1(:,:,:);
