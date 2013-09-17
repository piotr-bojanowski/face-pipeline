
addpath('face-detection');
addpath('tracking');

modelfile       = './face_p146_small.mat';
dump_string     = '/sequoia/data1/bojanows/thesis/AutoNaChar/S05E02/dump/S05E02_%06d.jpeg';

model_dir = './';
result_dir  = 'results';
shotpath    = fullfile(result_dir, 'shots.txt');
det_string  = fullfile(result_dir, '%06d.mat');

if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

facemodel = load(modelfile);

s1  = 14900;
s2  = 14910;
f   = s1:s2;

% box = cell(length(f), 1);
% for i = 1:length(f)
%     DetectFace(f(i), dump_string, det_string, facemodel);
% end

detectShots(s1, s2, dump_string, shotpath);

track_in_shots(result_dir, shotpath, -0.6, dump_string, det_string);

tracks_to_facedets(result_dir, model_dir, dump_string);

