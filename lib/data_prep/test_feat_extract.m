function [data_len, winlen, winstep] = test_feat_extract(audio_dir, f, f_name, save_dir) 

[noisy_speech, audio_sr] = audioread(audio_dir);  
y_label = cell2mat(struct2cell(load(strrep(audio_dir,'wav', 'mat')))); % label load
%y_label = np.zeros([len(noisy_speech), 1])
system(['mkdir ', save_dir,'\Labels']);
name_label = [save_dir , '\Labels\label'];

winlen     = ceil(audio_sr*25*0.001);	%window length (default : 25 ms)
winstep    = ceil(audio_sr*10*0.001);	%window step (default : 10 ms)

% print('Extracting ' + f_name + ' features')
name_feat = [save_dir , '\' , f_name];
if f == 3  % rasta_plp
    rplp = rastaplp(noisy_speech, audio_sr, 1, 18);
    rplp = rplp(1:end-1,:);
    del = deltas(rplp);
    ddel = deltas(deltas(rplp,5),5);
    feat_mat = [rplp;del;ddel]';
elseif f == 6  % energy and zero crossing
    [y,eng] = powspec(noisy_speech, audio_sr);
    zc = my_zero_cross(noisy_speech, audio_sr, winlen, winstep)';
    if length(zc) > length(eng)
        zc = zc(1:length(eng));
    else
        eng = eng(1:length(zc));
    end
    edel = deltas(eng);
    eddel = deltas(deltas(eng,5),5);
    zdel = deltas(zc);
    zddel = deltas(deltas(zc,5),5);
    feat_mat = [eng;edel;eddel;zc;zdel;zddel]';

end

train_mean = mean(feat_mat,1);
train_std = std(feat_mat,1,1);
framed_label = Truelabel2Trueframe(y_label, winlen, winstep);
num = 0;
if (length(feat_mat) >= length(framed_label))
    binary_saver(name_feat, feat_mat(1: length(framed_label),:), num );
    binary_saver(name_label, framed_label, num);
    data_len = length(framed_label);
else
    binary_saver(name_feat, feat_mat, num)
    binary_saver(name_label, framed_label(1: length(feat_mat)), num );
    data_len = length(feat_mat);
    
%sio.savemat(save_dir+r'\normalize_factor',{'train_mean': train_mean, 'train_std': train_std})
save([save_dir, '\normalize_factor'], 'train_mean', 'train_std')

end