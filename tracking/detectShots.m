function detectShots(s1, s2, dump_string, shotpath)

chunk_size  = 500;

chunk_start = num2cell(s1:(chunk_size - 2):s2);

shot_start = cell(1, length(chunk_start));
for i = 1:length(chunk_start)
    shot_start{i} = detectShotChange(chunk_start{i}, chunk_size, s2, dump_string);
end

shot_start = cell2mat(shot_start);
shot_start = [-100, s1, shot_start, s2+1];

% remove short shots and add them to the beginning of the next one
long_shot_start = shot_start(find(diff(shot_start)>4)+1);

% rewrite shots to read as S(1,i) = start frame / S(2,i) = end frame for shot i
shots = [long_shot_start(1:end-1) ; long_shot_start(2:end) - 1];
write_shots(shots, shotpath);

end