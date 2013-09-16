function [ shot_start ] = detectShotChange(chunk_start, chunk_size, s2, dump_string )
%DETECTSHOTCHANGE Summary of this function goes here
%   Detailed explanation goes here


chunk_end = min(chunk_start + chunk_size - 1, s2);
chunk_frames = chunk_start:chunk_end;


fprintf('Loading frames from %d to %d...\n', chunk_start, chunk_end);

imgs = readframes(dump_string, chunk_frames);

R           = cell2mat(cellfun(@(x) histc(reshape(x(:,:,1),[],1), 0:255), imgs, 'UniformOutput', false));
G           = cell2mat(cellfun(@(x) histc(reshape(x(:,:,2),[],1), 0:255), imgs, 'UniformOutput', false));
B           = cell2mat(cellfun(@(x) histc(reshape(x(:,:,3),[],1), 0:255), imgs, 'UniformOutput', false));


R = bsxfun(@times, R, 1./sum(R,1));
G = bsxfun(@times, G, 1./sum(G,1));
B = bsxfun(@times, B, 1./sum(B,1));

H = [R;G;B];

signal = sum(abs(diff(H, 1, 2)), 1);

N = 20;
window = ones(1,N)/N;

signal = [signal(1)*ones(1,N) signal signal(end)*ones(1,N)];

mean = conv(signal, window, 'same');

clf;
subplot(2,1,1);
plot(signal);
hold on;
plot(mean,'r');
subplot(2,1,2);
plot(signal./mean);
drawnow;

spikes = signal./mean;
spikes = spikes(N+1 : end-N);

shot_start = chunk_frames(spikes>3)+1;

% shot_change = sum(abs(diff(H, 1, 2)), 1) > 5 * mean(sum(abs(diff(H, 1, 2)), 1));
% shots       = chunk_frames(shot_change)+1;
% 
% clf;
% imagesc(abs(diff(H, 1, 2)));
% drawnow;

end

