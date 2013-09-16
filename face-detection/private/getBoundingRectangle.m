function [r, pose] = getBoundingRectangle(boxes, posemap)

count = 1;
if(length(boxes) == 0)
    r = [];
    score = [];
    pose = [];
    return;
end

for b = boxes,
    for i = size(b.xy,1):-1:1;
        x1 = b.xy(i,1);
        y1 = b.xy(i,2);
        x2 = b.xy(i,3);
        y2 = b.xy(i,4);

        x(i)= (x1+x2)/2;
        y(i)= (y1+y2)/2;
    end
    r(count, 1) = min(x);
    r(count, 2) = min(y);
    r(count, 3) = max(x);
    r(count, 4) = max(y);
    r(count, 5) = b.s;
    pose(count)  = posemap(b.c);
    count = count + 1;
    x = [];
    y = [];
end
