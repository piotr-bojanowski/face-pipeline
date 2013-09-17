function features_and_speakers(result_dir, model_dir, dump_string)

load(fullfile(result_dir, 'facedets.mat'));
load(fullfile(model_dir, 'mean_face.mat'));

facedets = face_features(facedets, dump_string);
facedets = face_descriptors(facedets, mean_face, 101, dump_string, model_dir);
facedets = mouth_motion(facedets, dump_string);
facedets = declare_speakers(facedets);

save(fullfile(result_dir, 'facedets.mat'));

end