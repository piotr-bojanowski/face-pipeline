function [ fd ] = search_mouth( fd, dumpfile )
%SEARCH_MOUTH Summary of this function goes here
%   Detailed explanation goes here

frm     = fd.frame;

% loading frame frm
impath  = sprintf(dumpfile, frm);
Im      = imread(impath);
Im      = double(Im) / 255;

% loading previous frame
impath  = sprintf(dumpfile, frm-1);
pIm     = imread(impath);
pIm     = double(pIm) / 255;
pIm     = mean(pIm,3);

% get face bounding box and face landmarks
% rect is of the form [x1 x2 y1 y2]
rect    = fd.rect;
pnts    = fd.P;
pose    = fd.pose;

% use mouth points to predict mouth position
if pose == 1 % frontal
    search_scalex = 4;
    search_scaley = 2;
    mouth_mid = mean(pnts(:,8:9),2);
    bb        = abs((pnts(1,8)-pnts(1,9))) * 0.25;
    hght      = abs((pnts(1,8)-pnts(1,9))) * 0.4;
    rectm     = [pnts(1,8)-bb pnts(1,9)+bb mouth_mid(2,1)-hght mouth_mid(2,1)+hght];
else % profile
    search_scalex = 3;
    search_scaley = 3;
    mouth_mid = pnts(:,5);
    bb        = (rect(2)-rect(1))*.15;
    hght      = (rect(2)-rect(1))*.2;
    if fd.mirror
        bb1 = bb*.8;
        bb2 = bb*1.2;
    else
        bb1 = bb*1.2;
        bb2 = bb*.8;
    end;
    rectm     = [mouth_mid(1)-bb1 mouth_mid(1)+bb2 mouth_mid(2)-hght mouth_mid(2)+hght];
end

% get the polygon
rectm       = round(rectm);

% extract mouth patch
mouthindy   = max(rectm(3), 1) : min(rectm(4), size(Im, 1));
mouthindx   = max(rectm(1), 1) : min(rectm(2), size(Im, 2));
mouth       = mean(Im(mouthindy,mouthindx,:),3);

% define search region
rectm2      = pp_rescale_rect(rectm, search_scalex, search_scaley); % small search window
rectm2      = round(rectm2);
searchindy  = max(rectm2(3), 1) : min(rectm2(4), size(pIm, 1));
searchindx  = max(rectm2(1), 1) : min(rectm2(2), size(pIm, 2));

% search in previous frame
pImm = pIm(searchindy, searchindx);
S    = vgg_ssd(pImm, mouth, 'ssd');

% find the minimum
[yp, ~] = min(S(:));

% getting the best match
[I, J]  = find(S==yp);
r2c2    = floor(size(mouth) / 2);
r2      = r2c2(1);
c2      = r2c2(2);
[r1 c1] = size(mouth);
match   = pImm(I-r2:I+(r1-r2)-1, J-c2 : J+(c1-c2)-1);

% store ssd to previous frame
fd.ssdpf = yp;
fd.npix  = numel(mouth);

% plotting the difference
figure(3),clf;
subplot(2,2,1);
imshow(mouth);
axis image;
title('querry mouth');
subplot(2,2,2);
imshow(match);
axis image;
title('querry mouth');
subplot(2,2,3);
imagesc(S);
axis image;
colormap('jet');
title(sprintf('SSD min: %.3f  nmin:%.3g', yp, yp/numel(mouth)));
subplot(2,2,4);
imagesc((mouth-match).^2);
axis image;
title('Difference from the last frame');
drawnow;

end


function rect_out = pp_rescale_rect(rect,scalex,scaley)

if nargin<3
    scaley = scalex;
end

wd  = rect(:,2)-rect(:,1);
hg  = rect(:,4)-rect(:,3);

x   = (rect(:,1)+rect(:,2))/2;
y   = (rect(:,3)+rect(:,4))/2;

wd2   = wd/2*scalex;
hg2   = hg/2*scaley;

rect_out = [x-wd2 x+wd2 y-hg2 y+hg2];

end