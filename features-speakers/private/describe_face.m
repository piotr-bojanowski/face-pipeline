function siftVec = describe_face(K, pose, model_dir)
%DESCRIBE_FACE Extracts face descriptors from "rectified" image K


% landmark descriptors parameters
s = [1,2]; % sift scale


% load the model files
t = load(fullfile(model_dir,'model_frontal.mat'),'model');
frontal_model = t.model;
t = load(fullfile(model_dir,'model_profile.mat'),'model');
t.model.appwt = 2;
profile_model = t.model;


% creating the face bounding box
N       = size(K,1);
det     = [(N-1)/2+1 (N-1)/2+1 ((N/3)-1)/2];
rect    = [N/3+1 N/3*2 N/3+1 N/3*2];


% according to the pose, modify the used model
switch pose
    case 1
        model   = frontal_model;
        Im      = K;
        VP      = {1,2,3,4,5,6,7,8,9,[1,2],[3,4],[8,9]};
    case 2
        model   = profile_model;
        Im      = K(:,end:-1:1,:);
        det(1)  = det(1)+det(3)*0.6;
        VP      = {1,2,3,4,5,6,[1,2]};
    case 3
        model   = profile_model;
        Im      = K;
        det(1)  = det(1)+det(3)*0.6;
        VP      = {1,2,3,4,5,6,[1,2]};
end


% try different bounding box sizes and keep most confident detection
conf = -inf;
for l = -3:3
    det1 = det;
    det1(3) = det1(3)*sqrt(1.31)^l;
    % find parts in image Im in bounding box det1
    [P1 , conf1 , aconf1] = findparts(model , Im , det1);
    if conf1 > conf
        conf    = conf1;
        aconf   = aconf1;
        P       = P1;
    end
end

% extracting SIFT on landmarks
[frames, siftVec] = get_sift_desc(Im, P, s, VP);

landmark_image = draw_landmarks(Im,P,2);

clf;
subplot(1, 2, 1);
imshow(landmark_image);
subplot(1, 2, 2);
imshow(Im);
hold on;
vl_plotsiftdescriptor(siftVec, frames);
axis(rect);
hold off;
drawnow;

end


function [ I ] = draw_landmarks( K , P , r )

[X0,Y0] = meshgrid(-r:r,-r:r);
R2  = X0.*X0 + Y0.*Y0;
M   = R2 <= r*r;
XY0 = [X0(M) , Y0(M)]';

I = permute(K,[2,1,3]);
for i = 1:size(P,2)
    P0 = round(bsxfun(@plus,XY0,P(:,i)));
    blob = sub2ind(size(I),P0(1,:),P0(2,:),2*ones(size(P0(1,:))));
    I(blob) = 255;
end

I = permute(I,[2,1,3]);

end
