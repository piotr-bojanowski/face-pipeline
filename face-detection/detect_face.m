function detect_face(frame , dump_string, det_string, facemodel)

detpath = sprintf(det_string, frame);

if exist(detpath, 'file')
    return;
end

% load specified frame from a dump folder
impath  = sprintf(dump_string, frame);
img     = imread(impath);

% set constants
threshold   = -1.3;
scale       = 1.5;
posemap     = 90:-15:-90;

facemodel.model.thresh = min(threshold, facemodel.model.thresh);
facemodel.model.interval = 5;

% upscale the image to 
im  = imresize(img, scale);

% detect faces in image
bs = detect_f(im, facemodel.model, facemodel.model.thresh);

% clip the boxes to image boundaries
bs = clipboxes(im, bs);

% perform non-maximum suppression
bs = nms_face(bs, 0.3);

% get the [x1, y1, x2, y2] bounding box and pose
[box, pose] = getBoundingRectangle(bs, posemap);

% re-scale to original image size
if ~isempty(box)
    box(:,1:4) = round(box(:, 1:4) / scale);
end

% concatenate bbox with pose
box = [box, pose'];

save(detpath, 'box');

end