function [P, pconf, PCONF, mirror] = get_landmarks(I , fd)
%GET_LANDMARKS detects facial features in image I for face fd


datapath = '/sequoia/data1/bojanows/thesis/AutoNaChar/data';


% load the model files
t = load(fullfile(datapath,'model_frontal.mat'),'model');
frontal_model = t.model;
t = load(fullfile(datapath,'model_profile.mat'),'model');
t.model.appwt = 2;
profile_model = t.model;


% instead of [x1 x2 y1 y2] use [x y r]
det = bb_to_xyr(fd.rect);


% depending on the face orientation,
%   - change the landmarks model
%   - flip the image
switch fd.pose
    case 1 % klaes frontal
        mirror  = false;
        Im      = I;
        model   = frontal_model;
    case 2 % klaes right
        mirror  = true;
        Im      = I( : , end:-1:1 , : );
        det(1)  = size(I, 2) + 1 - det(1);
        det(1)  = det(1) + det(3) * 0.6;
        model   = profile_model;
    case 3 % klaes left
        mirror  = false;
        Im      = I;
        det(1)  = det(1) + det(3) * 0.6;
        model   = profile_model;
end


% try different bounding box sizes and keep most confident detection
det(3)  = det(3) * sqrt(1.5);
pconf    = -inf;
for l = 0:1
    det1    = det;
    det1(3) = det1(3) * sqrt(1.5) ^ l;
    % find parts in image Im in bounding box det1
    [P1, conf1, aconf1] = findparts(model, Im, det1);
    if conf1 > pconf
        pconf   = conf1;
        PCONF   = aconf1;
        P       = P1;
    end
end


% re-flipping the x axis so that the coordinates are the true ones
if mirror
    P(1, : ) = size(I, 2) + 1 - P(1, : );
end

% removing the ear feature
if fd.pose == 2 || fd.pose == 3
    P( : , 6) = [];
end




% debug result visualisation
clf;
imagesc(I);
hold on;
for k = 1:size(P, 2)
    if ~any(P(:, k))
        break
    end
    plot(P(1, k), P(2, k), 'r+', 'linewidth', 2, 'markersize', 10);
    text(P(1, k) + 2, P(2, k) + 2, sprintf('%d', k), 'color', 'r');
end
hold off;
axis image;
drawnow;


end

function [ res ] = bb_to_xyr( bb )
%BB_TO_XYR Changes the bounding box format
%  bb is a bouunding box in the format [x1 x2 y1 y2]
%  res is a bounding box in the format [xc yc r]
%       where xc and yc are the center coordinates
%       and r is the box radius (max dimension)

scl = max(bb([2 4]) - bb([1 3])) / 2;
x   = mean(bb([1 2]));
y   = mean(bb([3 4]));
res = [x y scl]';

end