% make reco2dur file:
Path = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\clean\train';
FilePath = [Path,'\reco2dur'];
file_list = getAllFiles(Path, 'FileFilter','\.wav$');

fid = fopen(FilePath,'w');
for i = 1:length(file_list)
    file_i = cell2mat(file_list(i));
    [s,Fs] = audioread(file_i);
    file_len = length(s)/Fs; %[sec]
    line = ['timit_train',repmat('0',1,(3-length(num2str(i)))),num2str(i),...
        ' ',num2str(file_len)];
    fprintf(fid,'%s\n',line);
end
fclose(fid);
