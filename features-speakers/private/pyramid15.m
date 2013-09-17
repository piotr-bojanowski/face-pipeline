function PYR = pyramid15(I,nlevels,filter)

if nargin<3
    filter=false;
end

d=size(I,3);
PYR=cell(nlevels,1);
for i=1:nlevels
    PYR{i}=I;
    if filter
        I=single(I);
        I=imfilter(I,[.030 .105 .222 .286 .222 .105 .030],'replicate');
        I=imfilter(I,[.030 .105 .222 .286 .222 .105 .030]','replicate');
        I=double(I);
    end
	[M,N]=size(I);
	m=floor(M/1.5);
	n=floor(N/1.5);
	M=floor(m*1.5);
	N=floor(n*1.5);
	J=zeros(m,n,d);
	J(1:2:m,1:2:n,:)=I(1:3:M,1:3:N,:);
	J(1:2:m,2:2:n,:)=0.5*(I(1:3:M,2:3:N,:)+I(1:3:M,3:3:N,:));
	J(2:2:m,1:2:n,:)=0.5*(I(2:3:M,1:3:N,:)+I(3:3:M,1:3:N,:));
	J(2:2:m,2:2:n,:)=0.25*(I(2:3:M,2:3:N,:)+I(2:3:M,3:3:N,:)+I(3:3:M,2:3:N,:)+I(3:3:M,3:3:N,:));
    I=J;
end
