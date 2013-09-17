function [J,T0]=extface(model,I,det)

if size(I,3)==3
    I = rgb2gray(I);
end

I   = double(I)/255;

[X0,Y0] = meshgrid(1:model.imgsize,1:model.imgsize);

scale = det(3) / (model.imgsize/2 - model.border);
tx  = det(1) - scale*model.imgsize/2;
ty  = det(2) - scale*model.imgsize/2;
T0  = [scale 0 tx ; 0 scale ty];
lev = max(floor(log(scale)/log(1.5)),0)+1;
ps  = 1.5^(lev-1);
scale = scale/ps;
tx  = (tx-1)/ps+1;
ty  = (ty-1)/ps+1;
T   = [scale 0 tx ; 0 scale ty ; 0 0 1];

X1  = T(1,1)*X0+T(1,2)*Y0+T(1,3);
Y1  = T(2,1)*X0+T(2,2)*Y0+T(2,3);
PYR = pyramid15(I,lev);
J   = vgg_interp2(PYR{lev},X1,Y1,'linear',0); 

end
