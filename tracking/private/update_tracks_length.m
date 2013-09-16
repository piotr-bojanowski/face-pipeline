function tracks = update_tracks_length(tracks)
    if ~isfield(tracks, 'track')
        return
    end
    ids = cat(1, tracks(:).track);
    uids = unique(ids);
    for i = 1:length(uids)
        ind = find(ids == uids(i));
        for j = 1:length(ind)
            tracks(ind(j)).tracklength = length(ind);
        end
    end
end
