function [ fd ] = face_features( fd , dumpfile )
%FACE_FEATURES Extracts all facial features
% Given the global variable avifile, this function extracts all facial 
% features for all detections stored in structure fd. It calls the 
% function GET_LANDMARKS for every face detection. Frames are loaded by 
% groups of 500.
%
%       The input arguments are : 
%               - fd  : the face-detection structure used everywhere
%
%       The resulting feature locations are added to the fd
%       structure. The following fields are created : 
%               - P         : the landmark locations
%               - pconf     : global features confidence
%               - PCONF     : landmark-wise confidence
%               - mirror    : a deprecated flag


fd().P = [];
fd().pconf = [];
fd().PCONF = [];
fd().mirror = [];


frame   = cat(1, fd.frame);

f = unique(frame);

figure(1), clf;
set(1, 'Name', 'Facial Landmarks');

fprintf('Extracting Facial Features...\n' );
for i = f'
    fprintf('working on frame %06d... \n', i);    
    
    impath = sprintf(dumpfile, i);
    I = imread(impath);
    
    idx = find(frame == i);
    for j = 1:length(idx)
        k = idx(j);
        
        [P, pconf, PCONF, mirror] = get_landmarks(I, fd(k));
        fd(k).P = P;
        fd(k).pconf = pconf;
        fd(k).PCONF = PCONF;
        fd(k).mirror = mirror;
    end
end
fprintf('Done.\n');


end

