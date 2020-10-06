function [feat] = rasta_plp_ex(dir)
[noisy_speech,sr] = audioread(dir);
rplp = rastaplp(noisy_speech, audio_sr, 1, 18);
rplp = rplp(1:end-1,:);
del = deltas(rplp);
ddel = deltas(deltas(rplp,5),5);
feat = [rplp;del;ddel]';