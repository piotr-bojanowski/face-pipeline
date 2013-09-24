function [ K ] = sum_kernel( df, l )
%SUM_KERNEL Summary of this function goes here
%   Detailed explanation goes here

nc = size(df,3);

for i = 1:nc
    dt = df(:,:,i);
    gama = mean(dt( ~ isinf(dt))) * l;
    if gama==0
        gama=1;
    end
    df(:, :, i) = exp( - dt / gama );
end

K = sum(df, 3) / nc;


end

