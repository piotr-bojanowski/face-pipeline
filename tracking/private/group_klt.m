function dets = group_klt(dets, s1, s2, klt_mask, datadir, dump_string)
if isempty(dets), return; end

klt_path = fullfile(datadir, 'klt');
klt_dist_path = fullfile(datadir, 'klt_dist');

if ~exist(klt_path, 'file'), mkdir(klt_path); end
if ~exist(klt_dist_path, 'file'), mkdir(klt_dist_path); end

fdf = [dets.frame];

for step = [1, -1]
    if step == 1
        f1 = s1;
        f2 = s2;
    else
        f1 = s2;
        f2 = s1;
    end
    
    trkpath = fullfile(klt_path, sprintf('%06d-%06d_%d.mat', s1, s2, step));
    
    
    tc  = klt_init('nfeats', 1000,...
        'mindisp', 0.5,...
        'pyramid_levels', 2,...
        'mineigval', 1/(255^6),...
        'mindist', 5);
    K   = zeros(3, tc.nfeats, max(f1, f2) - min(f1, f2) + 1, 'single');
    
    f = f1;
    
    % reading frame
    im = readframes(dump_string, f);
    I = single(rgb2gray(im{1}))/255;
    
    M = dets_to_mask(dets, f, I, klt_mask);
    
    [tc, P] = klt_selfeats(tc, I, M);
    K(:, :, f - min(f1, f2) + 1) = P;
    
    if step == 1
        fprintf('Forward tracking of features\n');
    else
        fprintf('Backward tracking of features\n');
    end
    
    
    for f = (f1 + step):step:f2
        fprintf('\tFrame %d in [%d-%d]\r', f, f1, f2);
        
        % reading frame
        im = readframes(dump_string, f);
        I = single(rgb2gray(im{1})) / 255;
        
        M = dets_to_mask(dets, f, I, klt_mask);
        
        [tc, P] = klt_track(tc, P, I, []); % use mask here ?
        if f ~= f2
            [tc, P] = klt_selfeats(tc, I, M, P);
        end
        K(:,:,f - min(f1, f2) + 1) = P;
    end
    fprintf('\n');
    
    save(trkpath, 'K');
end

trkpathF = fullfile(klt_path, sprintf('%06d-%06d_1.mat', s1, s2));
trkpathB = fullfile(klt_path, sprintf('%06d-%06d_-1.mat', s1, s2));
distpath = fullfile(klt_dist_path, sprintf('%06d-%06d.mat', s1, s2));

if true || ~exist(distpath,'file')
    load(trkpathF, 'K');
    [TX, TY] = klt_parse_sparse(K);
    
    load(trkpathB, 'K');
    K = K(:, :, end:-1:1);
    [TXb, TYb] = klt_parse_sparse(K);
    TXb = TXb(end:-1:1, :);
    TYb = TYb(end:-1:1, :);
    TX = [TX TXb];
    TY = [TY TYb];
    
    FeatInBox = sparse(size(TX, 2), length(fdf));
    FeatInFrame = sparse(size(TX, 2), length(fdf));
    FeatInBox = logical(FeatInBox);
    FeatInFrame = logical(FeatInFrame);
    tic;
    fprintf('Associating klt tracks with detections\n');
    for i = 1:length(dets)
        if toc > 1 || i == length(dets)
            fprintf('\tDetection %d/%d\r', i, length(fdf));
            tic;
        end
        fa = dets(i).frame;
        bba = dets(i).rect;
        in_box = TX(fa - s1 + 1, :) > 0 &...
            TX(fa - s1 + 1, :) >= bba(1) &...
            TX(fa - s1 + 1, :) <= bba(3) &...
            TY(fa - s1 + 1, :) >= bba(2) &...
            TY(fa - s1 + 1, :) <= bba(4);
        in_f = TX(fa - s1 + 1, :) > 0;
        FeatInFrame(:, i) = in_f';
        FeatInBox(:, i) = in_box';
    end
    fprintf('\n');
    
    C = zeros(length(dets)); % similarity matrix
    NI = zeros(length(dets)); % number of intersecting tracks
    
    tic;
    fprintf('Computing klt tracks intersections\n');
    for i = 1:length(dets)
        
        C(i, i) = -inf;
        
        for j = 1:i-1
            
            if fdf(i) == fdf(j)
                c = -inf;
                ni = 0;
            else
                ni = sum(FeatInBox(:, i) & FeatInBox(:, j));
                
                c = full(ni / (sum((FeatInBox(:, i) & FeatInFrame(:, j)) | (FeatInBox(:, j) & FeatInFrame(:, i)))));
                
                
                %                     c = full(2 * ni / (sum(FeatInBox(:, i)) + sum(FeatInBox(:,j))));
                
                %                     c = full(ni / min(sum(FeatInFrame(:, i) & FeatInFrame(:, j)),sum(FeatInBox(:, i) | FeatInBox(:, j))));
            end
            
            C(i, j) = c;
            C(j, i) = c;
            NI(i, j) = ni;
            NI(j, i) = ni;
        end
        
        if toc > 1 || i == numel(dets)
            fprintf('\tDetection %d/%d\r', i, numel(dets));
            tic;
        end
    end
    fprintf('\n');
    
    
    save(distpath, 'C', 'NI');
else
    load(distpath, 'C', 'NI');
end

fdf = [dets.frame]';
FD = repmat(fdf, 1, numel(fdf)) - repmat(fdf', numel(fdf), 1);
C(~FD) = -inf;

clus = agglomclus(C, 0.5);

nc = 0;
for i = 1:length(clus)
    nc = nc + 1;
    for j = 1:length(clus{i})
        k = clus{i}(j);
        dets(k).track = nc;
    end
end

dets = update_tracks_length(dets);
dets = update_tracks_conf(dets);

end