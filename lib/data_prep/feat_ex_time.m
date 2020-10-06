% Parameters:
data_dir = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\train';
audio_sr = 16000;

% Get all files in data_dir
audio_list = getAllFiles(data_dir, 'FileFilter', '\.wav$');

winlen             = ceil(audio_sr*25*0.001);	%window length (default : 25 ms)
winstep            = ceil(audio_sr*10*0.001);	%window step (default : 10 ms)


for i=1:100
    noisy_speech = audioread(audio_list{i});  % noisy_speech load
    tic;
    rplp = rastaplp(noisy_speech, audio_sr, 1, 18);
    rplp = rplp(1:end-1,:);
    del = deltas(rplp);
    ddel = deltas(deltas(rplp,5),5);
    feat_mat = [rplp;del;ddel]';
    t(i) = toc;
end
mean(t)        