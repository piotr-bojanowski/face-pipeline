function [ fd ] = face_descriptors( fd , mean_face , imsz , dumpfile, model_dir )
%FACE_DESCRIPTORS Extracts facial descriptors for faces fd
%  This function takes as input face detections with landmark positions
%  already computed. It warps the face using a similarity transfor so that
%  landmarks positions correspond to the mean positions in the complete
%  video. Once the warping is done it recomputes landmark positions and
%  describe them using sift descriptors.
%
%       The input arguments are : 
%               - fd        : the face-detection structure used everywhere
%               - mean_face : the average face landmarks location
%               - imsz      : the size of the face after warping (101 px)
%               - debug     : if 1 will show landmark detections
%
%       The resulting face descriptors are added to the fd
%       structure. The following fields are created : 
%               - ??????????????????????


fd().dSIFT = [];

frame = cat(1,fd.frame);

f = unique(frame);

figure(2), clf;
set(2, 'Name', 'SIFTs on landmarks');

fprintf('Extracting Face Descriptors...\n');
for i = f'
    fprintf('working on frame %06d... \n',i);
    
    impath = sprintf(dumpfile, i);
    Im = imread(impath);

    if size(Im, 3)==1
        Im = repmat(Im, [1 1 3]);
    end
    
    idx = find( frame == i );

    for j = 1:length(idx)
        k = idx(j);
        
        pose    = fd(k).pose;
        P       = fd(k).P;
        
        % getting rectified image patch
        % K is centered on the face, of size [3*IMSZ x 3*IMSZ]
        % the face region is in the middle, of size [IMSZ x IMSZ]
        K = warp_face(Im, mean_face{pose}, P, imsz );
                
        % getting the face descriptors in the rectified image
        siftVec = describe_face(K, pose, model_dir);
        
        fd(k).dSIFT = double(siftVec(:));
        
    end
    
end
fprintf('Done.\n');
    
end

