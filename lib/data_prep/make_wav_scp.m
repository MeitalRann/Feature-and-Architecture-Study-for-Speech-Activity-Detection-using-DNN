% make wav.scp file:
FilePath = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\clean\train\wav.scp';

fid = fopen(FilePath,'w');
for i = 1:65
    row = ['timit_train',repmat('0',1,(3-length(num2str(i)))),num2str(i),...
        ' C:\meital\University\Madison\Thesis\VAD-py\data\raw\clean\train\timit_train'...
        ,repmat('0',1,(3-length(num2str(i)))),num2str(i),'.wav'];
    fprintf(fid,'%s\n',row);
end
fclose(fid);