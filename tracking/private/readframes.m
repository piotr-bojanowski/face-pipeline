function ims = readframes(dumpstring, frames)
    ims = cell(1, length(frames));
    for i = 1:length(frames)
        ims{i} = imageread(dumpstring, frames(i));
    end
end
