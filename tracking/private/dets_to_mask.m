function M = dets_to_mask(dets, frame, im, klt_mask)
    M = false(size(im, 1) , size(im, 2));
    v = find([dets.frame] == frame);
    for i = v
        bb = dets(i).rect;
        bb([1,3]) = max(min(bb([1,3]), size(im, 2)), 1);
        bb([2,4]) = max(min(bb([2,4]), size(im, 1)), 1);
        if isempty(klt_mask)
            M(bb(2):bb(4), bb(1):bb(3)) = true;
        else
            boxsize = [bb(4) - bb(2) + 1, bb(3) - bb(1) + 1];
            thismask = imresize(klt_mask, boxsize);
            M(bb(2):bb(4), bb(1):bb(3)) = (thismask > 0);
        end
    end
end