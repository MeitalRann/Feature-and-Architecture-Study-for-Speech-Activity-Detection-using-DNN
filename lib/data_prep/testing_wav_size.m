% testing_wav_size:
wav_file = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\train\timit_train001.wav';
mat_file = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\train\timit_train001.mat';
folder = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\testing_data\';

[signal,Fs] = audioread(wav_file);
trans = load(mat_file);
trans = cell2mat(struct2cell(trans));

% 1 min:
len = 60*Fs;
speech = signal(1:len);
y_label = trans(1:len);

audiowrite([folder,'timit_1.wav'],speech,Fs); % save audio to train folder
save([folder,'timit_1.mat'],'y_label')

% 5 min:
len = 5*60*Fs;
speech = signal(1:len);
y_label = trans(1:len);

audiowrite([folder,'timit_5.wav'],speech,Fs); % save audio to train folder
save([folder,'timit_5.mat'],'y_label')

% 10 min:
len = 10*60*Fs;
speech = signal(1:len);
y_label = trans(1:len);

audiowrite([folder,'timit_10.wav'],speech,Fs); % save audio to train folder
save([folder,'timit_10.mat'],'y_label')

% 15 min:
len = 15*60*Fs;
speech = signal(1:len);
y_label = trans(1:len);

audiowrite([folder,'timit_15.wav'],speech,Fs); % save audio to train folder
save([folder,'timit_15.mat'],'y_label')

% 20 min:
len = 20*60*Fs;
speech = signal(1:len);
y_label = trans(1:len);

audiowrite([folder,'timit_20.wav'],speech,Fs); % save audio to train folder
save([folder,'timit_20.mat'],'y_label')