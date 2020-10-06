% Make clean database for training the vad:

% Parameters:
min_len = 2*60; % [sec]
timit_folder = 'C:\meital\University\Madison\Thesis\Database\TIMIT\timit\TIMIT\TRAIN';
musan_folder = 'C:\meital\University\Madison\Thesis\Database\musan\noise';
out_train = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\clean\train';
out_valid = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\clean\valid';

%---------------
% If we don't have utt_data in the workspace, then should upload it.
if exist('utt_data','var') == 0  
    load utt_data.mat;
end
utt_data = utt_data(randperm(numel(utt_data))); % shuffle utt_data
m = 'dSbeEt';

j = 1;
Fs = 16000;
silence = zeros(Fs,1);
% make silece "real":
silence(1:2002:Fs) = 10^-4;
silence(1:555:Fs) = 10^-5;
silence(1:10:Fs) = 10^-6;
silence(1:51:Fs) = 2*10^-6;
speech_count = 0;
silence_count = 0;

n_train = round(length(utt_data)*0.95);
%---------------
% Train data:
%---------------
rec_j = []; % save the j's recording 
y_label = []; % new transcript to the j's recording
    
for i = 1:n_train
    % get utt_i:
    utt_data_i = strsplit(cell2mat(utt_data(i)),'_');
    wav_i = cell2mat(utt_data_i(1)); % wav recording name
    [speech,Fs] = audioread(wav_i); % get samples of wav
    
    % get beggining and ending points of the utterance:
    b = str2double(cell2mat(utt_data_i(2)));
    e = str2double(cell2mat(utt_data_i(3)));

    % get utterance with 1 sec silence before and after:
    utt_i = [silence;speech(b:e);silence]; % [samples]

    if (length(utt_i)+length(rec_j))/Fs > min_len
        audio_name = [out_train,'\timit_train',repmat('0',1,(3-length(num2str(j)))),num2str(j),'.wav'];
        rec_j = rec_j/max(abs(rec_j));
        audiowrite(audio_name,rec_j,Fs); % save audio to train folder
        save(strrep(audio_name,'wav','mat'),'y_label')
        j = j + 1;
        rec_j = [];
        y_label = [];
    end
    
    % add to rec_j
    rec_j = [rec_j;utt_i];
    % add trans_i to y_label:
    trans_i = [zeros(Fs,1);ones(length(speech(b:e)),1);zeros(Fs,1)]; % transcript
    y_label = [y_label;trans_i];
    speech_count = speech_count+length(speech(b:e));
    silence_count = silence_count+length(silence)*2;
end
audio_name = [out_train,'\timit_train',repmat('0',1,(3-length(num2str(j)))),num2str(j),'.wav'];
rec_j = rec_j/max(abs(rec_j));
audiowrite(audio_name,rec_j,Fs); % save audio to train folder
save(strrep(audio_name,'wav','mat'),'y_label')
j = j + 1;

%---------------
% Valid data:
%---------------
rec_j = []; % save the j's recording 
y_label = []; % new transcript to the j's recording
for i = n_train+1:length(utt_data)
    % get utt_i:
    utt_data_i = strsplit(cell2mat(utt_data(i)),'_');
    wav_i = cell2mat(utt_data_i(1)); % wav recording name
    [speech,Fs] = audioread(wav_i); % get samples of wav
    
    % get beggining and ending points of the utterance:
    b = str2double(cell2mat(utt_data_i(2)));
    e = str2double(cell2mat(utt_data_i(3)));

    % get utterance with 1 sec silence before and after:
    utt_i = [silence;speech(b:e);silence]; % [samples]

    if (length(utt_i)+length(rec_j))/Fs > min_len
        audio_name = [out_valid,'\timit_train',repmat('0',1,(3-length(num2str(j)))),num2str(j),'.wav'];
        rec_j = rec_j/max(abs(rec_j));
        audiowrite(audio_name,rec_j,Fs); % save audio to train folder
        save(strrep(audio_name,'wav','mat'),'y_label')
        j = j + 1;
        rec_j = [];
        y_label = [];
    end
    
    % add to rec_j
    rec_j = [rec_j;utt_i];
    % add trans_i to y_label:
    trans_i = [zeros(Fs,1);ones(length(speech(b:e)),1);zeros(Fs,1)]; % transcript
    y_label = [y_label;trans_i];
    speech_count = speech_count+length(speech(b:e));
    silence_count = silence_count+length(silence)*2;
end
audio_name = [out_valid,'\timit_train',repmat('0',1,(3-length(num2str(j)))),num2str(j),'.wav'];
rec_j = rec_j/max(abs(rec_j));
audiowrite(audio_name,rec_j,Fs); % save audio to train folder
save(strrep(audio_name,'wav','mat'),'y_label')
