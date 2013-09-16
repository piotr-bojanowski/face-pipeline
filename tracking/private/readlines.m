function lines=readlines(fname,l1,l2)

if nargin<2 l1=1; end
if nargin<3 l2=Inf; end
  
lines={};
fd=fopen(fname);
linenum=0;
notEOF=1;
while (notEOF & linenum<=l2),
  line=fgetl(fd);
  notEOF=ischar(line);
  if (notEOF),
    linenum=linenum+1;
    if linenum>=l1 & linenum<=l2
      lines{end+1}=line;
    end
  end
end
fclose(fd);
