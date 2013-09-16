function track_in_shots(result_dir, shotpath, conf_thresh, dump_string, det_string)

shots   = read_shots(shotpath);

for i = 1:size(shots, 2)
    s1 = shots(1, i);
    s2 = shots(2, i);
    
    shotString = sprintf('%07d_%07d', s1, s2);
    
    %%% DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    detfname    = sprintf('%s_dets.txt', shotString);
    detpath     = fullfile(result_dir, detfname);
    det         = [];
    for f = s1:s2
        load(sprintf(det_string, f), 'box');
        for j = 1:size(box, 1)
            det(end + 1).frame = f;
            det(end).conf      = box(j, 5);
            det(end).rect      = box(j, 1:4);
            det(end).pose      = box(j, 6);
        end
    end
    writetracks(det, detpath);
    
    %%% AGGLOMERATIVE CLUSTERING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    trackfname  = sprintf('%s_track_%3.2f.txt', shotString, conf_thresh);
    trackpath   = fullfile(result_dir, trackfname);
    det = readtracks(detpath);
    
    % second stage of thresholding to output different track files
    idx = [det.conf] > conf_thresh;
    det = det(idx);
    
    tracks = group_klt(det, s1, s2, [], result_dir, dump_string);
    
    writetracks(tracks,trackpath);
    
    %%% POST-PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    proctrackfname = sprintf('%s_processedtrack_%3.2f.txt', shotString, conf_thresh);
    proctrackpath = fullfile(result_dir, proctrackfname);
    tracks = readtracks(trackpath);
    proctracks = processtracks(tracks);
    writetracks(proctracks, proctrackpath);
    
end

end