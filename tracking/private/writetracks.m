function writetracks(tracks,tracksfname)

%
% id: ...
% avgscore: ...
% length: ...
%
%Following this header, list all bounding boxes in the format:
%
%<frame> <x> <y> <w> <h> <score>
%

% ids=cat(1,tracks(:).track);

fd = fopen(tracksfname, 'w');
fprintf(fd, '# format: <frame> <x> <y> <w> <h> <pose> <score>\n#\n');

if ~isempty(tracks)
    t = tracks(1);
    
    if isfield(t, 'track')
        tracks = update_tracks_length(tracks);
        ids = cat(1, tracks(:).track);
    else
        ids = 1:length(tracks);
    end
    
    [uids, i1, i2] = unique(ids);
    framesall=cat(1, tracks(:).frame);
    bboxall = cat(1, tracks(:).rect);
    confall = cat(1, tracks(:).conf);
    poseall = cat(1, tracks(:).pose);
    
    % set -Inf scores to -2
    confall(find(isinf(confall))) = -2;
    
    t = tracks(1);
    if isfield(t, 'trackconf')
        trackconfall = cat(1, tracks(:).trackconf);
        tracklengthall = cat(1, tracks(:).tracklength);
        trackconfall(find(isinf(trackconfall))) = -2;
    else
        trackconfall = confall;
        tracklengthall = ones(length(tracks), 1);
    end
    
    
    for i = 1:length(uids)
        id = uids(i);
        ind = find(ids == id);
        [vs, is] = sort(framesall(ind));
        ind = ind(is);
        if i > 1 fprintf(fd, '\n'); end
        fprintf(fd, '# id: %d\n', id);
        fprintf(fd, '# avgscore: %f\n', trackconfall(ind(1)));
        fprintf(fd, '# length: %d\n', tracklengthall(ind(1)));
        for j = 1:length(ind)
            k = ind(j);
            fprintf(fd,'%d  %d %d %d %d  %d %1.5f\n', round(framesall(k)), round(bboxall(k,:)), poseall(k), confall(k));
%             fprintf('%d  %d %d %d %d  %d %1.5f\n', round(framesall(k)), round(bboxall(k,:)), poseall(k), confall(k));
        end
    end
end

fclose(fd);
