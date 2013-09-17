function fd = declare_speakers(fd)


figure(4),clf;
set(4, 'Name', 'Speaker score, filtered score and thresholds.');

f_ssd_thr_spk     = 1.319 * 1e-3;  % speaking threshold
p_ssd_thr_spk     = 1.319 * 1e-3;  % speaking threshold
f_ssd_thr_nspk    = 0.6   * 1e-3;  % non-speaking threshold
p_ssd_thr_nspk    = 0.6   * 1e-3;  % non-speaking threshold


%%%% defining constants

feat_thr_frontal   = 0;
feat_thr_profile   = 30;
k                  = 3;             % window size for (max) filtering ssd score
mintrl_spk         = 1;             % do not predict for tracks shorter than mintrl_spk


% get the list of labels
tracklabel  = cat(1, fd.track);
featconf    = cat(1, fd.pconf);
pose        = cat(1, fd.pose);


[uqlbls, ia, ~]      = unique(tracklabel, 'first');

% compute the speaker score
ssdpl   = [fd.ssdpf] ./ [fd.npix];

% set to -1 the speaker score of faces with not confident landmarks
drop_p = ismember(pose,[2,3]) & featconf < feat_thr_profile;
drop_f = pose == 1 & featconf < feat_thr_frontal;

% set by default the speaker confidence score to -1
[fd.speakconf] = deal(0);

for i = 1:length(uqlbls)
    % get index to fd of track i
    relevant = (tracklabel==uqlbls(i));
    
    trlen = sum(relevant);
    [fd(relevant).trlen] = deal(trlen);
    
    idx = setdiff(find(relevant), ia);
    
    % getting continuous track pieces
    frames  = [fd(idx).frame];
    step    = diff(frames);
    breaks  = find(step>1);
    v = [[1; breaks'+1], [breaks'; length(idx)]];

    % filtering every piece with a median filter
    for j = 1:size(v, 1)
        idv = idx(v(j,1):v(j,2));
        S = ssdpl(idv);
        Sf = medfilt1(S, k);
        
        for k = 1:length(idv)
            fd(idv(k)).speakconf = Sf(k);
        end
        
        figure(4), clf;
        plot(S, 'blue', 'LineWidth', 2);
        hold on;
        plot(Sf, 'red', 'LineWidth', 2);
        plot(1:length(Sf), f_ssd_thr_spk * ones(1, length(Sf)), 'black', 'LineWidth', 2);
        plot(1:length(Sf), f_ssd_thr_nspk * ones(1, length(Sf)), 'black', 'LineWidth', 2);
    end
end

%%%% Assign speaking/non-speaking labels

for i = 1:length(fd)
    speakconf = fd(i).speakconf;
    trlen     = fd(i).trlen;
    fd(i).speak_aut = 0;
    
    if fd(i).pose == 1
        ssd_thr_nspk    = f_ssd_thr_nspk;
        ssd_thr_spk     = f_ssd_thr_spk;
    else
        ssd_thr_nspk    = p_ssd_thr_nspk;
        ssd_thr_spk     = p_ssd_thr_spk;
    end
    
    if trlen >= mintrl_spk && ~drop_p(i) && ~drop_f(i)
        if speakconf <= ssd_thr_nspk
            fd(i).speak_aut = 2; % non-speak
        elseif speakconf > ssd_thr_spk
            fd(i).speak_aut = 1;  % speak
        end
    end
end


end