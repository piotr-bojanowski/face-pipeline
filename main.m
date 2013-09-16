
addpath('face-detection');
addpath('tracking');

modelfile       = './face_p146_small.mat';
dump_string     = '/sequoia/data1/bojanows/thesis/AutoNaChar/S05E02/dump/S05E02_%06d.jpeg';

result_dir  = 'results';
shotpath    = fullfile(results, 'shots.txt');
det_string  = fullfile(results, '%06d.mat');

facemodel = load(modelfile);

s1  = 14900;
s2  = 14910;
f   = s1:s2;

box = cell(length(f), 1);
for i = 1:length(f)
    DetectFace(f(i), dump_string, det_string, facemodel);
end

detectShots(s1, s2, dump_string, shotpath);

track_in_shots(result_dir, shotpath, -0.6, dump_string, det_string);
% tracksvideo(result_dir, dump_string, shotpath, conf_thresh, 1, 1);
