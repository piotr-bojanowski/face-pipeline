% KLT_PARSE_SPARSE  Parse output of KLT tracker
% [TX,TY,v] = klt_parse_sparse(P) parses the output of the KLT tracker into
% distinct tracks. P is a 3 x nfeats x nframes array formed by
% concatenating the per-frame output of KLT_SELFEATS and KLT_TRACK. TX and
% TY are nframes x nfeats sparse matrices containing x and y coordinates
% respectively. v is a vector of ntracks elements containing the 'goodness'
% i.e. smaller eigenvalue of the feature in the first frame in which it
% appears.
%
% See also KLT_INIT, KLT_SELFEATS, KLT_TRACK.

function [TX,TY,v] = klt_parse_sparse(P)

nf=size(P,2);
ni=size(P,3);
nt=sum(sum(P(3,:,:)>0));

TX=sparse(ni,nt);
TY=sparse(ni,nt);
v=zeros(nt,1);

tic;
k=0;
for i=1:nf
    if toc>1
        fprintf('klt_parse_sparse: %d/%d\n',i,nf);
        tic;
    end
    for j=1:ni
        if P(3,i,j)>0
            k=k+1;
            v(k)=P(3,i,j);
        end
        if P(3,i,j)>=0
            TX(j,k)=P(1,i,j);
            TY(j,k)=P(2,i,j);
        end
    end
end
