function acoustic_feat_ex( data_dir, save_dir, feats,feats_name)

rng(0);
%% Directory setting

% system(['rm -rf ', save_dir]);
% 
% system(['mkdir ', save_dir]);
system(['mkdir ', save_dir, '\Normalize_Factor']);
system(['mkdir ', save_dir, '\Labels']);

%% Parameter setting

audio_sr = 16000;
split_num = 1;
name_feat = [save_dir,'\se_',feats_name];
name_label = [save_dir, '\se_label'];

audio_list = getAllFiles(data_dir, 'FileFilter', '\.wav$');
label_list = getAllFiles(data_dir, 'FileFilter', '\.mat$');

winlen             = ceil(audio_sr*25*0.001);	%window length (default : 25 ms)
winstep            = ceil(audio_sr*10*0.001);	%window step (default : 10 ms)

train_mean = 0;
train_std = 0;

for i = 1:1:length(audio_list)
    clc
    [feats_name,' extraxtion']
    %% Read audio
    
    noisy_speech = audioread(audio_list{i});  % noisy_speech load
    noisy_speech = noisy_speech(1:(length(noisy_speech)-mod(length(noisy_speech), split_num)));
    noisy_speech = reshape(noisy_speech, [], split_num);
    
    %% Caliculate feature
    if feats == 1  % mfcc
        coefs = mfcc(noisy_speech, audio_sr,'WindowLength',winlen,'OverlapLength',winlen-winstep,'NumCoeffs',40)';
        coefs = coefs(1:end-1,:);
        del = deltas(coefs);
        ddel = deltas(deltas(coefs,5),5);
        feat_mat = [coefs;del;ddel]';
    elseif feats == 3  % rasta_plp
        rplp = rastaplp(noisy_speech, audio_sr, 1, 18);
        rplp = rplp(1:end-1,:);
        del = deltas(rplp);
        ddel = deltas(deltas(rplp,5),5);
        feat_mat = [rplp;del;ddel]';
    elseif feats == 6  % energy and zero crossing
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
            

    
    size(feat_mat)
    %% Save normalization factor
    
    temp_mean = mean(feat_mat,1);
    temp_std = std(feat_mat,1,1);
    save([save_dir, '/Normalize_Factor/normalize_factor_', sprintf('%3.3d', i)],'temp_mean', 'temp_std');
    train_mean = temp_mean + train_mean;
    train_std = temp_std + train_std;
    
    %% Read label
    label = cell2mat(struct2cell(load(label_list{i})));  % label load
    
    %% Save framed label & MRCG
    framed_label = Truelabel2Trueframe( label, winlen, winstep );
    length(framed_label);
    if (length(feat_mat) >= length(framed_label))
        binary_saver( name_feat, feat_mat(1:length(framed_label), :), i-1 );
        binary_saver( name_label, framed_label, i-1 );
    else
        binary_saver( name_feat, feat_mat, i-1 );
        binary_saver( name_label, framed_label(1:length(feat_mat), 1), i-1 );
    end
end

disp('Feature extraction done.')
%% Save global normalization factor

global_mean = train_mean / length(audio_list);
global_std = train_std / length(audio_list);
save([save_dir, '/global_normalize_factor'], 'global_mean', 'global_std');

%% Move label data

feat_list = getAllFiles(save_dir);

for i=1:1:length(feat_list)
    if ~isempty(strfind(feat_list{i}, 'label'))
        [pathstr, name, ext] = fileparts(feat_list{i});
        new_path = [pathstr, '/Labels/', name, ext];
        movefile(feat_list{i}, new_path);
    end
end

end