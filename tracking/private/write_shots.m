function write_shots(shots,fname)

fid = fopen(fname,'w');
fprintf(fid,'%d %d\n',shots);
fclose(fid);

end