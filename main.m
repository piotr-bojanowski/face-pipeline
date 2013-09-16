
addpath('face-detection/');


save_string     = './%06d.mat';
modelfile       = './face_p146_small.mat';
dump_string     = '/sequoia/data1/bojanows/thesis/AutoNaChar/S05E02/dump/S05E02_%06d.jpeg';

facemodel = load(modelfile);

f = 14400;

box = cell(length(f), 1);
for i = 1:length(f)
    box{i} = DetectFace(f(i), dump_string, facemodel);
end

