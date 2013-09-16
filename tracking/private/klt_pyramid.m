function pyr = klt_pyramid(tc,I)

ww=2*tc.winsize+1;
I=mre_gaussian_filter(I,tc.smooth_sigma_factor*ww,'replicate');

pyr=cell(tc.pyramid_levels,1);
for i=1:tc.pyramid_levels
    pyr{i}.I=I;
    [pyr{i}.GX,pyr{i}.GY]=mre_gaussian_deriv_filter(I,tc.grad_sigma,'replicate');
    if i+1<=tc.pyramid_levels
        I=mre_gaussian_filter(I,tc.pyramid_sigma,'replicate');
        I=I(1:2:size(I,1),1:2:size(I,2));
    end
end


% ww=2*tc.winsize+1;
% I=mre_gaussian_filter(I,tc.smooth_sigma_factor*ww);
% 
% pyr=cell(tc.pyramid_levels,1);
% for i=1:tc.pyramid_levels
%     pyr{i}.I=I;
%     [pyr{i}.GX,pyr{i}.GY]=mre_gaussian_deriv_filter(I,tc.grad_sigma);
%     if i+1<=tc.pyramid_levels
%         I=mre_gaussian_filter(I,tc.pyramid_sigma);
%         I=I(1:2:size(I,1),1:2:size(I,2));
%     end
% end
% 
