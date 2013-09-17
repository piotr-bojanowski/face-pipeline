function [fd] = mouth_motion(fd, dumpfile)
% estimate lip motion
% josef@robots.ox.ac.uk 27/6/2006
% cleaned up by Piotr Bojanowski 17/1/2013


fprintf('Extracting Mouth Motion...\n');

figure(3);
set(3, 'Name', 'Frame by frame difference');

[~, idx] = sort([fd.frame]);
fd = fd(idx);

% get list of tracks
tracklabel  = [fd(:).track];
[~, ia, ~]  = unique(tracklabel, 'first');

% initialize containers
[fd.npix]     = deal(-1);
[fd.ssdpf]    = deal(0);

todo_idx = setdiff(1:length(fd), ia);

% start from the second frame in the face track (as we compute SSD to the previous frame)
for j = todo_idx
    fprintf('working on frame %06d... \n', fd(j).frame);
    fd(j) = search_mouth(fd(j), dumpfile);
end

fprintf('Done.\n');

end