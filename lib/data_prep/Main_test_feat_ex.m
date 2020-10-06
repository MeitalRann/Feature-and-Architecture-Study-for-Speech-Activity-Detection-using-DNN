% Main feature extraction (test):
feats_name = 'eng_zc';
feats = 6;

% test folders:
SfolderName = 'C:\meital\University\Madison\Thesis\VAD-py\sample_data';
DfolderName = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test';

% clean:
dir_name = 'clean';
save_dir = [SfolderName, '\' , dir_name , '\' , feats_name];
data_dir = [DfolderName,'\',dir_name];
run_feat_ex(data_dir, save_dir, feats, feats_name)

% noisy:
dir_name = 'noisy';
subfolders = GetSubDirs([DfolderName,'\',dir_name]);
for i =1: length(subfolders)
    sub_dir_name =  cell2mat(subfolders(i));
    save_dir = [SfolderName, '\' ,sub_dir_name,'\', feats_name];
    data_dir = [DfolderName,'\', dir_name , '\' ,sub_dir_name];
    run_feat_ex(data_dir, save_dir, feats, feats_name)
end

% recorded testset:
dir_name = 'recorded_data';
subfolders = GetSubDirs([DfolderName,'\',dir_name]);
for i =1: length(subfolders)
    sub_dir_name = cell2mat(subfolders(i));
    save_dir = [SfolderName, '\' ,sub_dir_name,'\', feats_name];
    data_dir = [DfolderName,'\', dir_name , '\' ,sub_dir_name];
    run_feat_ex(data_dir, save_dir, feats, feats_name)
end

% noise dependent testset:
dir_name = 'matched';
save_dir = [SfolderName, '\' , dir_name , '\' , feats_name];
data_dir = [DfolderName,'\',dir_name];
run_feat_ex(data_dir, save_dir, feats, feats_name)