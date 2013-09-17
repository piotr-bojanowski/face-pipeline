function [P,maxconf,partconf] = findparts(model,I,det)

[J,T0]=extface(model,I,det);

II=reshape(mre_intimg_cols(J(:),size(J)),size(J)+1);

AC=zeros(model.imgsize,model.imgsize,model.nparts);
for p=1:model.nparts
    AC(:,:,p)=-model.appwt*mre_haarcascade_masked(II,int32([model.winsize model.winsize]),model.part(p).Hcas,model.part(p).TALPHA,model.part(p).M);
end            

maxconf=-inf;
for t=1:length(model.tree)

    B=ones(model.imgsize,model.imgsize,model.nparts)*inf;
    argB=zeros(model.imgsize,model.imgsize,model.nparts);
    
    P=zeros(2,model.nparts);

    for c=model.tree(t).depthorder(end:-1:1)

        off=model.tree(t).MU(:,c);
        if off(1)>=0
            bb(1)=1;
            bb(2)=model.imgsize-off(1);
        else
            bb(1)=-off(1)+1;
            bb(2)=model.imgsize;
        end
        if off(2)>=0
            bb(3)=1;
            bb(4)=model.imgsize-off(2);
        else
            bb(3)=-off(2)+1;
            bb(4)=model.imgsize;
        end
                        
        C=ones(model.imgsize)*inf;
        C(bb(3):bb(4),bb(1):bb(2))=...
            AC((bb(3):bb(4))+off(2),(bb(1):bb(2))+off(1),c);
        for g=model.tree(t).children{c}
            C(bb(3):bb(4),bb(1):bb(2))=C(bb(3):bb(4),bb(1):bb(2))+...
                B((bb(3):bb(4))+off(2),(bb(1):bb(2))+off(1),g);
        end

        if model.tree(t).parent(c)
            C=C/model.tree(t).scale(c);
            [D,L]=mre_disttransform(C);
            D=D*model.tree(t).scale(c);
            B(:,:,c)=D;
            argB(:,:,c)=double(L)+off(1)*model.imgsize+off(2);
        else
            [conf,mini]=min(C(:));
            [P(2,c),P(1,c)]=ind2sub([model.imgsize model.imgsize],mini);
            conf=-conf;
        end
    end
    
    for c=model.tree(t).depthorder(2:end)
        p=model.tree(t).parent(c);
        mini=argB(P(2,p),P(1,p),c);
        [y,x]=ind2sub([model.imgsize model.imgsize],mini);
        P(:,c)=[x;y];
    end
    
    conf=conf+log(model.tree(t).mix);
    
    if conf>maxconf
        maxconf=conf;
        Pbest=P;
        tbest=t;
    end
end

P=T0*[Pbest ; ones(1,model.nparts)];
partconf=-AC(sub2ind(size(AC),Pbest(2,:),Pbest(1,:),1:model.nparts))';
