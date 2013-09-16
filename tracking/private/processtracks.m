function proctracks = processtracks(tracks, lenthresh, ovthresh, do_short_pruning, do_interpolation, do_overlap_pruning, do_smoothing)
if nargin<2, lenthresh = 8; end
if nargin<3, ovthresh = 0.3; end
if nargin<4, do_short_pruning = true; end
if nargin<5, do_interpolation = true; end
if nargin<6, do_overlap_pruning = true; end
if nargin<7, do_smoothing = true; end

fprintf('Tracks post-processing options:');
if ~do_short_pruning && ~do_interpolation && ~do_overlap_pruning && ~do_smoothing, fprintf(' none'); end
if do_short_pruning, fprintf(' short-tracks-pruning'); end
if do_interpolation, fprintf(' interpolation'); end
if do_overlap_pruning, fprintf(' overlapping-tracks-pruning'); end
if do_smoothing, fprintf(' smoothing'); end
fprintf('\n');


if ~isempty(tracks)
    tracks = update_tracks_length(tracks);
    tracks = update_tracks_conf(tracks);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SHORT TRACKS PRUNING
if ~isempty(tracks) && do_short_pruning
    tracks = update_tracks_length(tracks);
    if lenthresh > 0 % remove short tracks
        tracks = tracks([tracks(:).tracklength] > lenthresh);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% INTERPOLATION
if ~isempty(tracks) && do_interpolation
    ids         = cat(1, tracks(:).track);
    framesall   = cat(1, tracks(:).frame);
    uids        = unique(ids);
    
    for i = 1:length(uids) % interpolate the gaps
        id      = uids(i);
        ind     = find(ids == id);
        frames  = framesall(ind);
        [~, is] = sort(frames);
        ind     = ind(is);
        frames  = frames(is);
        
        % now detections in the track are sorted w.r.t. frames
        indgaps = find(diff(frames) > 1 & diff(frames) < 6);
        
        subtracks = [];
        for j = 1:length(indgaps)
            subtrack = interpolatetrack(tracks(ind(indgaps(j))), tracks(ind(indgaps(j) + 1)));
            subtracks = [subtracks subtrack];
        end
        if ~isempty(subtracks)
            tracks = [tracks subtracks]; 
        end
        
    end
    
    tracks = update_tracks_length(tracks);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% OVERLAPPING TRACKS PRUNING
if ~isempty(tracks) && do_overlap_pruning
    ids = cat(1, tracks(:).track);
    framesall = cat(1, tracks(:).frame);
    bboxall = cat(1, tracks(:).rect);
    keepflags = true(size(framesall));
    [uids, i1, ~] = unique(ids);
    
    if ovthresh > 0 % remove overlapping tracks
        
        utrackconf = [tracks(i1).trackconf];
        [~,is] = sort(utrackconf);
        for i = 1:length(is)
            id = uids(is(i));
            ind = find(ids == id);
            
            ovall = zeros(length(ind), 1);
            % compute overlap
            for j = 1:length(ind)
                frame = framesall(ind(j));
                indsameframe = setdiff(find(framesall == frame & keepflags), ind(j));
                if ~isempty(indsameframe)
                    ovall(j) = max(bboxoverlapval(bboxall(ind(j),:), bboxall(indsameframe,:)));
                end
            end
            % mark the track as removed if the mean overlap is above threshold
            if mean(ovall) > ovthresh
                keepflags(ind) = false;
            end
        end
        % remove tracks
        tracks = tracks(keepflags);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SMOOTHING
if ~isempty(tracks) && do_smoothing
    
    ids         = cat(1, tracks(:).track);
    framesall   = cat(1, tracks(:).frame);
    bboxall     = cat(1, tracks(:).rect);
    uids        = unique(ids);
    
    for i = 1:length(uids)
        ind = find(ids == uids(i));
        [~,is]  = sort(framesall(ind));
        ind     = ind(is);
        bbox    = bboxall(ind,:);
        crect   = bbox2crect(bbox);
        
        cx = crect(:,1);
        cy = crect(:,2);
        rx = crect(:,3);
        ry = crect(:,4);
        
        cx = medianFilter(cx, 3);
        cy = medianFilter(cy, 3);
        rx = medianFilter(rx, 3);
        ry = medianFilter(ry, 3);
        
        bbox = round(crect2bbox([cx,cy,rx,ry]));
        
        for j = 1:length(ind)
            tracks(ind(j)).rect = bbox(j,:);
        end
    end
end
proctracks = tracks;

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% ADDITIONAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [ bbox ] = crect2bbox( crect )
%CRECT2BBOX Summary of this function goes here
%   Detailed explanation goes here

bbox = zeros(size(crect));
if ~isempty(crect)
    bbox(:,1) = crect(:,1) - crect(:,3);
    bbox(:,2) = crect(:,2) - crect(:,4);
    bbox(:,3) = crect(:,1) + crect(:,3);
    bbox(:,4) = crect(:,2) + crect(:,4);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [crect] = bbox2crect(bbox)


crect =zeros(size(bbox));
if ~isempty(bbox)
    crect(:,1) = mean(bbox(:,[1 3]),2);
    crect(:,2) = mean(bbox(:,[2 4]),2);
    crect(:,3) = bbox(:,3) - crect(:,1);
    crect(:,4) = bbox(:,4) - crect(:,2);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function subtrack = interpolatetrack(det1,det2)

assert(det1.track == det2.track);
assert((det2.frame - det1.frame) > 1);

rect1 = det1.rect;
rect2 = det2.rect;
frames = (det1.frame + 1):(det2.frame - 1);

for i = 1:length(frames)
    w = i / (length(frames) + 2);
    subtrack(i) = det1;
    subtrack(i).frame = frames(i);
    subtrack(i).conf = -inf;
    subtrack(i).rect = rect1 * (1-w) + rect2 * w;
end

end
