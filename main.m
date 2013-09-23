
vl_feat_path = '/meleze/data0/libs/vlfeat-0.9.14/toolbox/vl_setup';

dump_dir = 'dump';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath('face-detection');
addpath('tracking');
addpath('features-speakers');
% addpath('generate-video');

run(vl_feat_path);

dump_string = fullfile(dump_dir, '%06d.jpg');
model_dir   = 'models';
result_dir  = 'results';

if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

s1  = 14870;
s2  = 14920;

face_detection(result_dir, model_dir, dump_string, s1, s2);

detect_shots(result_dir, dump_string, s1, s2);

track_in_shots(result_dir, -0.6, dump_string);

tracks_to_facedets(result_dir, model_dir, dump_string);

features_and_speakers(result_dir, model_dir, dump_string);

%%% use the following on unix systems with ffmpeg installed
% tracksvideo(result_dir, dump_string);