% prepare recorded_data test set for the VAD:

% Parameters:
min_len =3*60; % [sec]
in_folder = 'C:\meital\University\Madison\Thesis\Database\Recorded_data';
out_folder = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\recorded_data';

%----------------------------------
 % Get all files from the in_folder:
 wav_list = getAllFiles(in_folder, 'FileFilter','\.wav$');
 mat_list = getAllFiles(in_folder, 'FileFilter','\.mat$');
 
 % run through the lists and cut to smaller recordings:
 Fs = 16000;
 silence = zeros(1*Fs,1);
 % make silece "real":
silence(1:2002:Fs) = 10^-4;
silence(1:555:Fs) = 10^-5;
silence(1:8:Fs) = 10^-6;
silence(1:51:Fs) = 2*10^-6;

for i=1:length(wav_list)
    wav_i = cell2mat(wav_list(i));
    [Sound,Fs] = audioread(wav_i);
    
    file_name = split(wav_i,'\'); file_name = cell2mat(strrep(file_name(end),'.wav',''));
    
    mat_i = cell2mat(mat_list(i));
    trans = cell2mat(struct2cell(load(mat_i)));
    
    n = length(Sound);
    m = floor((n/Fs)/min_len);
    len = round(n/m);
    beg_p = 1;
    end_p = min(beg_p+len,n);
    add_s = 0;
    
    for j=1:m
        
        if trans(end_p) == 1
            for k = end_p+1: n
                if trans(k) == 0
                    end_p = k+1;
                    
                    break
                end
            end
        end
        
        
        rec = Sound(beg_p:end_p);  % add 30 sec of selence at the end
        rec = [silence;rec/max(abs(rec));silence];
        y_label = [zeros(1*Fs,1);trans(beg_p:end_p);zeros(1*Fs,1)]; % add 30 sec of selence at the end
%         if max(y_label) == 0
%             beg_p = end_p + 1;
%             end_p = min(beg_p+len,n);
%             continue
%         end
            
        
        % save rec and label:
        name_i = [out_folder,'\',file_name,'\',file_name,'_',num2str(j)];
        audiowrite([name_i,'.wav'],rec,Fs); 
        save([name_i,'.mat'],'y_label');
                
        beg_p = end_p + 1;
        end_p = min(beg_p+len,n);
        
    end
    
end