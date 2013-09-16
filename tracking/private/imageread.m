function im = imageread(dump_string, frame)
    im = imread(sprintf(dump_string, frame));
end
