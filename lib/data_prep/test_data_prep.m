% Make database for testing the VAD:

% Parameters:
min_len = 4*60; % [sec]
timit_folder = 'C:\meital\University\Madison\Thesis\Database\TIMIT\timit\TIMIT\TEST';
noisex_folder = 'C:\meital\University\Madison\Thesis\Database\noisex\example';
out_test_noisy = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\noisy';
out_test_clean = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\clean';
noise_test = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\noise\test';
stage = 3;
exit_stage = 3;

%-----------------------------------
% First step: prepare noise recordings:
%-----------------------------------
if stage <= 1 && exit_stage>= 1 
    A = 1; % amplitude of noise 

    % Get all wav files from the musan_folder:
    noisex_list = getAllFiles(noisex_folder, 'FileFilter','\.mat$');

    % Run through the noisex_list, make sure they are no longer than min_len
    % and save them to noise_test:
    Fs = 16000;

    for i=1:length(noisex_list)
        file_i = cell2mat(noisex_list(i));
        file_name = split(file_i,'\'); file_name = cell2mat(strrep(file_name(end),'.mat',''));
        sound_i = load(file_i); % get noise signal
        sound_i = cell2mat(struct2cell(sound_i));
        sound_i = resample(sound_i,1600,1998);
        
        num_rec = 4;  % number of files to create 
        
        for j = 1:num_rec
            wav_name = [noise_test,'\',file_name,'_',num2str(j),'.wav'];
            sound_save = sound_i;
            sound_save = sound_save/max(abs(sound_save));
            sound_save = sound_save*A;
            audiowrite(wav_name,sound_save,Fs); % save audio to train folder 

        end
    end
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
    save utt_data_test.mat utt_data
end

%-----------------------------------
% Third step: randomly add utterance with silence to the long noise recs.
%-----------------------------------
if stage <= 3 && exit_stage>= 3
    % If we don't have utt_data in the workspace, then should upload it.
    if exist('utt_data','var') == 0  
        load utt_data_test.mat;
    end
%     utt_data = utt_data(randperm(numel(utt_data))); % shuffle utt_data
    m = 'dSbeEtK'; % dSbeEt

    % Get all noise recs from test directory:
    noise_test_list = getAllFiles(noise_test, 'FileFilter','\.wav$','Depth',1);
    
%     j = 1;
    Fs = 16000;
    silence = zeros(Fs,1);
    snr_list = [-5,0,5,10]; % [dB]
    count = 1;
    % Run through the noise_train_list:
    for i=1:length(noise_test_list)
        rec_i = cell2mat(noise_test_list(i));
        [noise_i,Fs] = audioread(rec_i);
        %file_name = split(rec_i,'\'); file_name = cell2mat(strrep(file_name(end),'.mat',''));
        name_i =split(rec_i,'\'); 
        name_i = [out_test_noisy,'\',cell2mat(name_i(end))];
        
        new_signal = []; % new recording of noice and utterances + silence
        y_label = []; % new transcript to the recording
        % choose snr for the recording:
        snr_i = snr_list(count);
        
        while length(rec_i) <= length(noise_i)
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
                new_signal = new_signal/max(abs(new_signal));
                audiowrite(name_i,new_signal,Fs); % save audio to train folder
                save(strrep(name_i,'wav','mat'),'y_label')
                count = count + 1;
                if count == 5
                    count = 1;
                end
                break
            end
            
            trans_j = [silence;ones(length(speech(b:e)),1);silence]; % transcript
            
            noise_cut = noise_i(length(new_signal)+1:length(new_signal)+length(utt_j));
            
            % add noise and utt
            z = v_addnoise(utt_j,Fs,snr_i,m,noise_cut); 
            new_signal = [new_signal;z];
            y_label = [y_label;trans_j];
            
            j = j+1;
        end
    end
    
   
   %------------------------
   % create clean test set:
   %------------------------
   file_count = 1; % count number of files created
   num_files = 8;

   % make silece "real":
   silence(1:2002:Fs) = 10^-4;
   silence(1:555:Fs) = 10^-5;
   silence(1:10:Fs) = 10^-6;
   silence(1:51:Fs) = 2*10^-6;

   for i=1:num_files
       clean_rec = []; % new clean i's recording
       y_label = []; % new transcript to the i's recording
       while i<=num_files
           k = round(1+rand*(length(utt_data)-1));
           utt_data_k = strsplit(cell2mat(utt_data(k)),'_');
           wav_k = cell2mat(utt_data_k(1)); % wav recording name
           [speech,Fs] = audioread(wav_k); % get samples of wav

            % get beggining and ending points of the utterance:
            b = str2double(cell2mat(utt_data_k(2)));
            e = str2double(cell2mat(utt_data_k(3)));

            % get utterance with 1 sec silence before and after:
            utt_k = [silence;speech(b:e);silence]; % [samples]

            if (length(utt_k)+length(clean_rec))/Fs > min_len
                audio_name = [out_test_clean,'\timit_test',repmat('0',1,(3-length(num2str(file_count)))),num2str(file_count),'.wav'];
                clean_rec = clean_rec/max(abs(clean_rec));
                audiowrite(audio_name,clean_rec,Fs); % save audio to train folder
                save(strrep(audio_name,'wav','mat'),'y_label')
                file_count = file_count + 1;
                clean_rec = [];
                y_label = [];
                break
            end

            % add to clean_rec
            clean_rec = [clean_rec;utt_k];
            % add trans_k to y_label:
            trans_k = [zeros(Fs,1);ones(length(speech(b:e)),1);zeros(Fs,1)]; % transcript
            y_label = [y_label;trans_k];
       end
   end


end

    


