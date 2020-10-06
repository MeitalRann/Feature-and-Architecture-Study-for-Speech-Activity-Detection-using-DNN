% noise dependent test set prep:

% Parameters:
min_len = 3*60; % [sec]
timit_folder = 'C:\meital\University\Madison\Thesis\Database\TIMIT\timit\TIMIT\TEST';
noise_folder = 'C:\meital\University\Madison\Thesis\Database\General6000';
out_test = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\noise_dep';
stage = 2;
exit_stage = 3;

%-----------------------------------
% First step: create cell objects with utterances data s.a. rec name, 
%              beggining, end of utterance
%-----------------------------------
if stage <= 1 && exit_stage>= 1
    % Get all wWRD files from the timit_folder:
    timit_wrd_list = getAllFiles(timit_folder, 'FileFilter','\.WRD$','Depth',2);
    
    % Run through the timit_wav_list:
    formatSpec = '%d %d %*s'; % format of transcription file
    size_trans = [2,inf];
    utt_data = {}; % cell object to save all utterance data (rec name, begining, ending)
    Fs = 16000;
    
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
% Second step: create long speech recs:
%-----------------------------------
if stage <= 2 && exit_stage>= 2
    % If we don't have utt_data in the workspace, then should upload it.
    if exist('utt_data_dep','var') == 0  
        load utt_data_dep.mat;
    end
    
    A = 1; % amplitude of speech 
    
    % Run through the musan_list and add files together until reach the
    % rec_len:
    minute_counts = 0;
    rec = []; % new recording
    y_label = []; % new transcript to the recording
    Fs = 16000;
    file_count = 1;
    
    silence = zeros(Fs,1);
    silence(1:2002:Fs) = 10^-4;
    silence(1:555:Fs) = 10^-5;
    silence(1:10:Fs) = 10^-6;
    silence(1:51:Fs) = 2*10^-6;
    
    file_num = length(utt_data);

    % create speech recs 
    for i=1:file_num 
        utt_data_i = strsplit(cell2mat(utt_data(i)),'_');
        wav_i = cell2mat(utt_data_i(1)); % wav recording name
        [speech,Fs] = audioread(wav_i); % get samples of wav

        % get beggining and ending points of the utterance:
        b = str2double(cell2mat(utt_data_i(2)));
        e = str2double(cell2mat(utt_data_i(3)));

        % get utterance with 1 sec silence before and after:
        utt_i = [silence;speech(b:e);silence]; % [samples]
        trans_j = [zeros(Fs,1);ones(length(speech(b:e)),1);zeros(Fs,1)]; % transcript
        
        if length(rec)+length(utt_i) >= min_len*Fs 
            if isempty(rec) == 0 % make sure rec is not empty
                wav_name = ['timit_test',repmat('0',1,(3-length(num2str(file_count)))),num2str(file_count),'.wav'];
                rec = A*rec/max(abs(rec));
                minute_counts = minute_counts + (length(rec)/Fs)/60;
                
                audiowrite([out_test,'\',wav_name],rec,Fs); % save audio to train folder
                save(strrep([out_test,'\',wav_name],'wav','mat'),'y_label')
                
                rec = [];
                y_label = [];
                file_count = file_count+1;
            end
        end

        rec = [rec;utt_i];
        y_label = [y_label;trans_j];
    end
    
    wav_name = ['timit_test',repmat('0',1,(3-length(num2str(file_count)))),num2str(file_count),'.wav'];
    audiowrite([out_test,'\',wav_name],rec,Fs); 
    save(strrep([out_test,'\',wav_name],'wav','mat'),'y_label')
end

%-----------------------------------
% Third step: add noise:
%-----------------------------------
if stage <= 3 && exit_stage>= 3
    % Get all wav files from the noise_folder:
    noise_list = getAllFiles(noise_folder, 'FileFilter','\.wav$');
    noise_list = noise_list(randperm(numel(noise_list))); % shuffle list

    m = 'dSbeEtK';
    minute_counts = 0;
    Fs = 16000;
    
    % Get all noise recs from train directory:
    test_list = getAllFiles(out_test, 'FileFilter','\.wav$','Depth',1);
    file_count = length(test_list);
   
    snr_list = [-5,0,5,10]; % [dB]
    
    j=1;
    
    % Run through the out_test:
    for i=1:length(test_list)
        test_i = cell2mat(test_list(i));
        [rec_i,Fs] = audioread(test_i);
        rec_len = length(rec_i);
        
        new_rec = []; % new recording of noise and utterances
        
        
%         rand_ind = randi(length(snr_list), 1);
%         snr_i = snr_list(rand_ind);
        snr_i = choose_snr(snr_list,length(test_list),i);
        
        while length(new_rec) < rec_len
            noise_j = cell2mat(noise_list(j));
            [noise_j,fs] = audioread(noise_j);           
            
            % Make sound_i one channel signal with sampling rate of 16kHz:
            [n,m] = size(noise_j);
            if m > 1
                noise_j = noise_j(:,1);
            end
            % make sure noise rec is not too short (more then 0.2 sec)
            if length(noise_j) < 0.2*fs
                j = j+1;
                continue
            end
            if fs ~= Fs
                [Numer, Denom] = rat(Fs/fs);
                y = resample(noise_j, Numer, Denom);
                noise_j = y;
            end
            
            % add noise to speech signal
            if length(new_rec)+length(noise_j)<=rec_len   
                speech_cut = rec_i(length(new_rec)+1:length(new_rec)+length(noise_j));
            else
                speech_cut = [rec_i(length(new_rec)+1:end);zeros(length(noise_j)-length(rec_i(length(new_rec)+1:end)),1)];
                
            end
            
            noisy_signal = v_addnoise(speech_cut,Fs,snr_i,m,noise_j); % add noise and utt
            new_rec = [new_rec;noisy_signal];
            j=j+1;
            
        end
        new_rec = new_rec(1:rec_len);
        new_rec = new_rec/max(abs(new_rec));
        audiowrite(test_i,new_rec,Fs);
    end
end