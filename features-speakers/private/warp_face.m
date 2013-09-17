function [ K ] = warp_face(Im, mP, P, imsz)
%WARP_FACE Summary of this function goes here
%   Detailed explanation goes here

[ X0 , Y0 ] = meshgrid( (1-imsz):2*imsz , (1-imsz):2*imsz );

[scale,theta,tx,ty] = mre_est_simtran_2d( mP , P );
T = [scale*cos(theta) scale*sin(theta) tx ; -scale*sin(theta) scale*cos(theta) ty];

% resample face to the rectified frame
X1 = T(1,1)*X0 + T(1,2)*Y0 + T(1,3);
Y1 = T(2,1)*X0 + T(2,2)*Y0 + T(2,3);
bb = [floor(min(X1(:))) ceil(max(X1(:))) floor(min(Y1(:))) ceil(max(Y1(:)))];
bb = min( max(bb,1) , [size(Im,2) size(Im,2) size(Im,1) size(Im,1)] );

J = Im( bb(3):bb(4) , bb(1):bb(2) , : );
J = mre_gaussian_filter( J , scale/2 , 'replicate' );

K = zeros(3*imsz,3*imsz,3);
for ikk=1:3
    K(:,:,ikk) = interp2(double(J(:,:,ikk))-1,X1-bb(1)+1,Y1-bb(3)+1,'linear',nan);
end;

K = uint8(K);
        
end

