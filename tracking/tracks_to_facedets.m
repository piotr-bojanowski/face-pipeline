function tracks_to_facedets(result_dir, model_dir, dump_string, s1, s2)
% fields to create :
%       fd.frame
%       fd.rect [x1 x2 y1 y2]
%       fd.pose

% in the tracks file the bbox is as [x1 y1 x2 y2]
% in the warping is a function of   [x1 y1 x2 y2]
% in facedets it should be saved as [x1 x2 y1 y2]

load(fullfile(model_dir, 'W.mat'));
load(fullfile(model_dir, 'pose_cor.mat'));

listing = dir(fullfile(result_dir,  '*_*_processedtrack.txt'));

f   = [];
rect    = [];
pose    = [];
trackid = [];
conf    = [];

last_track = 0;

for i = 1:length(listing)
    trackpath = fullfile(result_dir, listing(i).name);
    tracks = readtracks(trackpath);
    
    if ~isempty(tracks)
        trackid = cat(1, trackid, last_track + [tracks.track]');
        f   = cat(1, f, [tracks.frame]');
        rect    = cat(1, rect, cat(1,tracks.rect));
        pose    = cat(1, pose, [tracks.pose]');
        conf    = cat(1, conf, [tracks.conf]');
        
        last_track = max(trackid);
    end
end

deva_poses = -90:15:90;

for i = 1:length(deva_poses)
    temp_pose = deva_poses(i);
    id = find(pose==temp_pose);
    rect(id,:) = round(rect(id,:) * W{i});
    pose(id) = pose_cor(i);
end

% get to [x1 x2 y1 y2]
rect = rect(:, [1,3,2,4]);

% sorting in frames
[~,id] = sort(f);
f   = f(id, :);
rect    = rect(id, :);
pose    = pose(id, :);
trackid = trackid(id, :);
conf    = conf(id, :);

% plotting a few frames for checking
permutation = randperm(length(f));
for i = permutation(1:10)
    r = rect(i,:);
    box = [r(1) r(3) r(2)-r(1)+1 r(4)-r(3)+1];
    
    
    clf;
    imshow(sprintf(dump_string, f(i)));
    hold on;
    rectangle('Position', box, 'EdgeColor', 'red', 'LineWidth', 2);
    hold off;
    drawnow;
    pause(0.3);
end

facedets = struct(  'frame', num2cell(f), ...
    'rect', num2cell(rect',1)', ...
    'pose', num2cell(pose), ...
    'track', num2cell(trackid), ...
    'conf', num2cell(conf));

facedetfname    = 'facedets.mat';
facedetpath     = fullfile(result_dir, facedetfname);
save(facedetpath, 'facedets');


end