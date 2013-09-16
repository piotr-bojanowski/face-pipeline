% KLT_INIT  Initialize KLT tracker
%   tc = klt_init(optname, optval, ...) initializes a KLT tracking context.
%   See this source file for options.
%
%   See also KLT_SELFEATS, KLT_TRACK, KLT_PARSE.

function tc = klt_init(varargin)

tc.nfeats=1000;       % max number of features
tc.winsize=3;        % window (feature) size is 2*x+1
tc.mindist=10;        % minimum distance between selected features

tc.mineigval=1/(255^2);   % minimum 2nd eigenvalue of slected features (must be >0)
                     % NB: birchfield equivalent is 1/(255^2)

tc.maxresidual=10/255; % maximum residual (mean abs error) of tracked feature

tc.smooth_sigma_factor=0.1; % smooth image with sigma x*(2*winsize+1)
tc.grad_sigma=1;            % smooth with sigma for gradients

tc.pyramid_levels=4;    % number of pyramid levels (subsampled by 2)
tc.pyramid_sigma=1.8;   % smooth with sigma before subsampling

tc.maxiters=10;     % maximum iterations of newton method

tc.mindet=1e-2/(255^4);     % minimum determinant for position update
                    
tc.mindisp=0.1;     % minimum change in position (pixels) before terminating

% status codes

tc.klt_tracked=0;       % tracked
tc.klt_notfound=-1;     % no feature selected
tc.klt_smalldet=-2;     % fail: small determinant
tc.klt_maxiters=-3;     % fail: maximum iterations exceeded
tc.klt_oob=-4;          % fail: out of image/mask
tc.klt_largeresid=-5;   % fail: large residual

if nargin
    tc=vgg_argparse(tc,varargin);
end
