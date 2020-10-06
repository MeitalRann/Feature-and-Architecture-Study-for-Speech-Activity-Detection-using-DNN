% Make database for training the vad:

% Parameters:
min_len = 4*60; % [sec]
timit_folder = 'C:\meital\University\Madison\Thesis\Database\TIMIT\timit\TIMIT\TEST';
noise_folder = 'C:\meital\University\Madison\Thesis\Database\General6000';
out_test = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\matched';
%noise_test = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\noise\test\matched';
noise_test = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\noise\valid';
output_folder = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\matched';
stage = 3;
exit_stage = 3;

%-----------------------------------
% First step: create long noise recs:
%-----------------------------------
if stage <= 1 && exit_stage>= 1
%     % Create windows for mergind different sound files:
%     win_len = 200; % [samples]
%     left_win = (0:1/win_len:1)'; % (left)
%     right_win = (1:-1/win_len:0)'; % (right)

    num_noise = 410; % choose only 300 noises from the database
    
    A = 1; % amplitude of noise 

    % Get all wav files from the musan_folder:
    noise_list = getAllFiles(noise_folder, 'FileFilter','\.wav$');
    noise_list = noise_list(randperm(numel(noise_list))); % shuffle list

    % Run through the noise_list and add files together until reach the
    % rec_len:
    file_count = 1; % count number of files created
    minute_counts = 0;
    rec = [];
    Fs = 16000;
    

    % create noise recs 
    for i=1:num_noise
        file_i = cell2mat(noise_list(i));
        [sound_i, fs] = audioread(file_i); % get noise signal
        
        % Make sound_i one channel signal with sampling rate of 16kHz:
        [n,m] = size(sound_i);
        if m > 1
            sound_i = sound_i(:,1);
        end
        if fs ~= Fs
            [Numer, Denom] = rat(Fs/fs);
            y = resample(sound_i, Numer, Denom);
            sound_i = y;
        end
        
        % if the sound_i is longer then min_len, save it separetly
        if length(sound_i) >= min_len*Fs 
            in = floor(length(sound_i)/(min_len*Fs));
            for j = 1:in
                wav_name = ['noise_test',repmat('0',1,(3-length(num2str(file_count)))),num2str(file_count),'.wav'];
                sound_save = sound_i((j-1)*min_len*Fs+1:j*min_len*Fs);
                sound_save = A*sound_save/max(abs(sound_save));
                minute_counts = minute_counts + (length(sound_save)/Fs)/60;  
                
                audiowrite([noise_test,'\',wav_name],sound_save,Fs); % save audio to train folder    
                
                file_count = file_count+1;
            end
            sound_i = sound_i(in*min_len*Fs+1:end);
        end
        
        if length(rec)+length(sound_i) >= min_len*Fs 
            if isempty(rec) == 0 % make sure rec is not empty
                wav_name = ['noise_test',repmat('0',1,(3-length(num2str(file_count)))),num2str(file_count),'.wav'];
                rec = A*rec/max(abs(rec));
                minute_counts = minute_counts + (length(rec)/Fs)/60;
                 
                audiowrite([noise_test,'\',wav_name],rec,Fs); % save audio to train folder 

                rec = [];
                file_count = file_count+1;
            end
        end

        % Make the noise equal energy:
        if isempty(rec) ~= 1
            rec_e = sum(rec.^2)/length(rec);
            sound_e = sum(sound_i.^2)/length(sound_i);
            sound_i = sqrt(rec_e/sound_e)*sound_i;
        end
        rec = [rec;sound_i];
            
        
    end
    rec = A*rec/max(abs(rec));
    wav_name = ['noise_test',repmat('0',1,(3-length(num2str(file_count)))),num2str(file_count),'.wav'];
    audiowrite([noise_test,'\',wav_name],rec,Fs); % save audio to valid folder
    minute_counts
end

%-----------------------------------
% Second step: create cell objects with utterances data s.a. rec name, 
%              beggining, end of utterance
%-----------------------------------
if stage <= 2 && exit_stage>= 2
    % Get all wWRD files from the timit_folder:
    timit_wrd_list = getAllFiles(timit_folder, 'FileFilter','\.WRD$','Depth',2);
    
    % Run through the timit_wav_list:
    formatSpec = '%d %d %*s'; % format of transcription file
    size_trans = [2,inf];
    utt_data = {}; % cell object to save all utterance data (rec name, begining, ending)
    
    for i=1:length(timit_wrd_list)
        wrd_i = cell2mat(timit_wrd_list(i));
        
        fileID = fopen(wrd_i,'r');
        words_loc = fscanf(fileID,formatSpec,size_trans)'; % read transcription
        fclose(fileID);
        words_info = add_diff(words_loc); % add 3rd column with the space between words
        
        % Add utterance data (rec_name,beggining,ending) to utt_data:
        name = strrep(wrd_i,'WRD','wav');
        beg = -1;
        [m,n] = size(words_info);
        for j=1:m
            utt_data_j = words_info(j,:);
            if utt_data_j(end) == inf % last word
                if beg == -1
                    data = strjoin({name,num2str(utt_data_j(1)),num2str(utt_data_j(2))},'_');
                    utt_data = [utt_data,data];
                else
                    data = strjoin({name,num2str(beg),num2str(utt_data_j(2))},'_');
                    utt_data = [utt_data,data];
                end
            elseif utt_data_j(end) <= Fs/4
                if beg == -1
                    beg = utt_data_j(1);
                end
            else
                if beg == -1
                    data = strjoin({name,num2str(utt_data_j(1)),num2str(utt_data_j(2))},'_');
                    utt_data = [utt_data,data];
                else
                    data = strjoin({name,num2str(beg),num2str(utt_data_j(2))},'_');
                    utt_data = [utt_data,data];
                    beg = -1;
                end
            end
        end
    end
    save utt_data_dep.mat utt_data
end

%-----------------------------------
% Third step: randomly add utterance with silence to the long noise recs.
%-----------------------------------
if stage <= 3 && exit_stage>= 3
    % If we don't have utt_data in the workspace, then should upload it.
    if exist('utt_data_dep','var') == 0  
        load utt_data_dep.mat;
    end
%     utt_data = utt_data(randperm(numel(utt_data))); % shuffle utt_data
    m = 'dSbeEtK';
    minute_counts = 0;
    
    Fs = 16000;
    % make silece "real":
    silence = zeros(Fs,1);
    silence(1:2002:Fs) = 10^-4;
    silence(1:555:Fs) = 10^-5;
    silence(1:10:Fs) = 10^-6;
    silence(1:51:Fs) = 2*10^-6;

    %---------------
    % Train data:
    %---------------
    % Get all noise recs from train directory:
    noise_train_list = getAllFiles(noise_test, 'FileFilter','\.wav$','Depth',1);
    %file_count = length(noise_train_list);
    file_count = 40;
    
   
    speech_count = 0;
    silence_count = 0;
    snr_list = [-5,0,5,10]; % [dB]
    % Run through the noise_train_list:
    for i=1:file_count
        rec_i = cell2mat(noise_train_list(i));
        [noise_i,Fs] = audioread(rec_i);
        
        new_signal = []; % new recording of noice and utterances + silence
        y_label = []; % new transcript to the recording
        % choose snr for the recording:
        snr_i = choose_snr(snr_list,length(noise_train_list),i);
        
        while length(new_signal) < length(noise_i)
            j = round(1+rand*(length(utt_data)-1));
            utt_data_j = strsplit(cell2mat(utt_data(j)),'_');
            wav_j = cell2mat(utt_data_j(1)); % wav recording name
            [speech,Fs] = audioread(wav_j); % get samples of wav
            
            % get beggining and ending points of the utterance:
            b = str2double(cell2mat(utt_data_j(2)));
            e = str2double(cell2mat(utt_data_j(3)));
            
            % get utterance with 1 sec silence before and after:
            utt_j = [silence;speech(b:e);silence]; % [samples]
            
            if length(utt_j) > length(noise_i)-length(new_signal)
                
                %audio_name = strrep(strrep(rec_i,'noise_','timit_'),'\noise\','\');
                audio_name = [output_folder,'\','timit_test',repmat('0',1,(3-length(num2str(i)))),num2str(i),'.wav'];
                new_signal = new_signal/max(abs(new_signal));
                audiowrite(audio_name,new_signal,Fs); % save audio to train folder
                minute_counts = minute_counts + length(new_signal)/Fs/60;
                save(strrep(audio_name,'wav','mat'),'y_label')
                break
            end
            
            trans_j = [zeros(Fs,1);ones(length(speech(b:e)),1);zeros(Fs,1)]; % transcript
            speech_count = speech_count+length(speech(b:e));
            silence_count = silence_count+length(silence)*2;
            
            % add utt to noise signal
            noise_cut = noise_i(length(new_signal)+1:length(new_signal)+length(utt_j));
            noisy_signal = v_addnoise(utt_j,Fs,snr_i,m,noise_cut); % add noise and utt
            new_signal = [new_signal;noisy_signal];
            y_label = [y_label;trans_j];
            
            
        end
    end
    
    minute_counts

end  
    
    
    