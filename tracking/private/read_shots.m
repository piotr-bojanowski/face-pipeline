function shots = read_shots(fname)

fid = fopen(fname);
S = textscan(fid,'%d %d');
fclose(fid);

shots = double(cell2mat(S)');

end