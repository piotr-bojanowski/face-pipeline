function ind=findcellstr(str1,str2,flag)

%  ind=findcellstr(str1,str2,flag)
%  
%  Search strings in 'str1' cell array containing
%  all substrings (case 'flag'='and') from string cell
%  array 'str2' or at least one substring from
%  'str2' if 'flag'='or'. Default 'flag'='and'
%

if nargin<3
  flag='and';
end

sz1=prod(size(str1));
sz2=prod(size(str2));
occmat=zeros(sz1,sz2);
for i=1:sz1
  for j=1:sz2
    occmat(i,j)=length(findstr(str1{i},str2{j}));
  end
end

ind=[];
if prod(size(occmat))
  if strcmp(flag,'or')
    ind=find(sum(occmat,2));
  else
    ind=find(prod(occmat,2));
  end
end