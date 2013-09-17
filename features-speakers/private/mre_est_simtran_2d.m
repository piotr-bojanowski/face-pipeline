% MRE_EST_SIMTRAN_2D    estimate 2-D least-squares similarity transform
%   [scale,theta,tx,ty] = mre_est_simtran_2d(P,Q) returns the parameters of
%   the similarity transform mapping points P to Q in the least-squares
%   sense. Columns of P and Q are 2-D points
%
%   The returned parameters satisfy:
%
%   [scale*cos(theta) scale*sin(theta) tx ; -scale*sin(theta) scale*cos(theta) ty] [P ; 1] ~= Q

function [scale,theta,tx,ty]=mre_est_simtran_2d(P,Q)

n=size(P,2);

% rotation

xdp = repmat(P(1,:),n,1) - repmat(P(1,:)',1,n);
ydp = repmat(P(2,:),n,1) - repmat(P(2,:)',1,n);
lp = sqrt(xdp.*xdp + ydp.*ydp);

xdq = repmat(Q(1,:),n,1) - repmat(Q(1,:)',1,n);
ydq = repmat(Q(2,:),n,1) - repmat(Q(2,:)',1,n);
lq = sqrt(xdq.*xdq + ydq.*ydq);

val=lp>0 & lq>0;

xdp(val) = xdp(val) ./ lp(val);
ydp(val) = ydp(val) ./ lp(val);

xdq(val) = xdq(val) ./ lq(val);
ydq(val) = ydq(val) ./ lq(val);

xv = xdp(val) .* xdq(val) + ydp(val) .* ydq(val);
yv = xdp(val) .* ydq(val) - ydp(val) .* xdq(val);
lv = sqrt(xv.*xv + yv.*yv);
xv = xv ./ lv;
yv = yv ./ lv;

costh = mean(xv);
sinth = mean(yv);
lcs = sqrt(costh*costh + sinth*sinth);
costh = costh / lcs;
sinth = -sinth / lcs;

theta = atan2(sinth, costh);

% scale

cp = mean(P,2);
dp = P - repmat(cp,1,n);
lp = sqrt(dp(1,:).*dp(1,:) + dp(2,:).*dp(2,:));

cq = mean(Q,2);
dq = Q - repmat(cq,1,n);
lq = sqrt(dq(1,:).*dq(1,:) + dq(2,:).*dq(2,:));

scale = sum(lq)/sum(lp);

% translation

ecq = [scale*costh scale*sinth ; -scale*sinth scale*costh] * cp;
t = cq - ecq;
tx = t(1);
ty = t(2);

end