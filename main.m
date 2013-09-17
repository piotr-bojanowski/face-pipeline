
addpath('face-detection');
addpath('tracking');
addpath('features-speakers');

run('/meleze/data0/libs/vlfeat-0.9.14/toolbox/vl_setup');

dump_string = '/sequoia/data1/bojanows/thesis/AutoNaChar/S05E02/dump/S05E02_%06d.jpeg';
model_dir   = './';
result_dir  = 'results';

if ~exist(result_dir, 'dir')
    mkdir(result_dir);
end

s1  = 14900;
s2  = 14920;

face_detection(result_dir, model_dir, dump_string, s1, s2);

detect_shots(result_dir, dump_string, s1, s2);

track_in_shots(result_dir, shotpath, -0.6, dump_string, det_string);

tracks_to_facedets(result_dir, model_dir, dump_string);

features_and_speakers(result_dir, model_dir, dump_string);
