function tracks = readtracks(tracksfname)
 
%
%# id: ...
%# avgscore: ...
%# length: ...
%
%Following this header, list all bounding boxes in the format:
%
%<frame> <x1> <y1> <x2> <y2> <pose> <score> 
%
  
l = readlines(tracksfname);
idind = findcellstr(l, {'id:'});
confind = findcellstr(l, {'avgscore:'});
lengthind = findcellstr(l, {'length:'});
assert(isequal(idind + 1, confind))
assert(isequal(idind + 2, lengthind))

detnum = 0;
tracks = [];

for i = 1:length(idind)
  k = idind(i);
  id = str2num(regexprep(l{k}, '#|id:| ', ''));
  trackconf = str2num(regexprep(l{k + 1}, '#|avgscore:| ', ''));
  tracklength = str2num(regexprep(l{k + 2}, '#|length:| ', ''));
  for j = 1:tracklength
    ind = (j+k+2);
    assert(ind <= length(l) & length(l{ind}) > 0 & l{ind}(1) ~= '#')
    val = str2num(l{ind});
    assert(length(val) == 7);
    bbox = val(2:5);
    pose = val(6);
    tracks(detnum + 1).frame = val(1);
    tracks(detnum + 1).conf = val(7);
    tracks(detnum + 1).rect = bbox;
    tracks(detnum + 1).pose = pose;
    tracks(detnum + 1).track = id;
    tracks(detnum + 1).trackconf = trackconf;
    tracks(detnum + 1).tracklength = tracklength;
    detnum = detnum + 1;
  end
end

if isempty(tracks)
    tracks = struct('frame', {},...
                    'conf', {},...
                    'rect', {},...
                    'pose', {},...
                    'track', {},...
                    'trackconf', {},...
                    'tracklength', {});
end
