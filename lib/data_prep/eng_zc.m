function feat_mat = eng_zc(noisy_speech, audio_sr, winlen, winstep)
[y,eng] = powspec(noisy_speech, audio_sr);
zc = my_zero_cross(noisy_speech, audio_sr, winlen, winstep)';
if length(zc) > length(eng)
    zc = zc(1:length(eng));
else
    eng = eng(1:length(zc));
end
edel = deltas(eng);
eddel = deltas(deltas(eng,5),5);
zdel = deltas(zc);
zddel = deltas(deltas(zc,5),5);
feat_mat = [eng;edel;eddel;zc;zdel;zddel]';