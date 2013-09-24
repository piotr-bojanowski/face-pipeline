function facedets_kernel(result_dir)

load(fullfile(result_dir, 'facedets.mat'));

track = cat(1, facedets.track);
utrack = unique(track);

n = length(utrack);

pose = cat(1, facedets.pose);
pconf = cat(1, facedets.pconf);

frontal = pose==1;
profile = pose~=1;

% working on frontal faces
idx = (frontal & pconf > 0);
facedets_f = facedets(idx);
S = cat(2, facedets_f.dSIFT);
d = size(S, 1);
K = d / 128;
dff = inf(n,n,K);

if n~=0
    for k = 1:K
        %     fprintf('Profile, channel %d\n', k);
        dim1 = (k-1)*128 + 1;
        dim2 = k*128;
        S_c = S( dim1 : dim2, :)';
        
        D = W_dist(S_c, S_c, eye(size(S_c, 2)));
        
        for i = 1:length(utrack)
            idxi = track(idx) == utrack(i);
            
            if sum(idxi)~=0
                for j = 1:length(utrack)
                    idxj = track(idx) == utrack(j);
                    if sum(idxj)~=0
                        d = D(idxi, idxj);
                        dff(i,j,k) = min(d(:));
                    end
                end
            end
        end
    end
end

% working on profile
idx = (profile & pconf > 30);
facedets_f = facedets(idx);
S = cat(2, facedets_f.dSIFT);
d = size(S, 1);
K = d / 128;
dfp = inf(n,n,K);

if n~=0
    for k = 1:K
        %     fprintf('Frontal, channel %d\n', k);
        dim1 = (k-1)*128 + 1;
        dim2 = k*128;
        S_c = S( dim1 : dim2, :)';
        
        D = W_dist(S_c, S_c, eye(size(S_c, 2)));
        
        for i = 1:length(utrack)
            idxi = track(idx) == utrack(i);
            
            if sum(idxi)~=0
                for j = 1:length(utrack)
                    idxj = track(idx) == utrack(j);
                    if sum(idxj)~=0
                        d = D(idxi, idxj);
                        dfp(i,j,k) = min(d(:));
                    end
                end
            end
        end
    end
end

dff = single(dff);
dfp = single(dfp);

K = sum_kernel(cat(3, dff, dfp), 1);

save(fullfile(result_dir, 'kernel.mat'), 'K');

end