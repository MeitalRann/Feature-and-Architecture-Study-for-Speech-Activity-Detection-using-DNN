% Main feature extraction:
feats_name = 'rasta_plp';
feats = 3;
folderName = 'C:\meital\University\Madison\Thesis\VAD-py\data\feat';
feat_dir = [folderName, '\', feats_name];
system(['mkdir ', feat_dir]);
% mkdir C:\meital\University\Madison\Thesis\VAD-py\data\feat\  rasta_plp

% train:
train_save_dir = [feat_dir,'\train'];
system(['mkdir ', train_save_dir]);
% mkdir C:\meital\University\Madison\Thesis\VAD-py\data\feat\rasta_plp\ train
data_dir = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\train';
acoustic_feat_ex( data_dir, train_save_dir, feats,feats_name)

train_norm_dir = [train_save_dir,'global_normalize_factor.mat'];
test_norm_dir = ['C:\meital\University\Madison\Thesis\VAD-py\norm_data\',feats_name,'\global_normalize_factor.mat'];
system(['copy ',train_norm_dir,' ',test_norm_dir]);

% valid:
valid_save_dir = [feat_dir,'\valid'];
system(['mkdir ', valid_save_dir]);
% mkdir C:\meital\University\Madison\Thesis\VAD-py\data\feat\rasta_plp\ valid
data_dir = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\valid';
acoustic_feat_ex( data_dir, valid_save_dir, feats,feats_name)

