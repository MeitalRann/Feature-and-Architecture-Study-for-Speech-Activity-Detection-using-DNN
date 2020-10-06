import os
import librosa
import numpy as np
import scipy.io as sio
import mrcg as mrcg
import mracc as mracc
import mel_spectrogram as mel_spec
import ams_ex as ams_ex
import rasta_plp as rsta_plp
import mrmfcc as mr_mfcc
import gfcc as gfcc
import matlab.engine



def Frame_Length( x,overlap,nwind ):
    nx = len(x)
    noverlap = nwind - overlap
    framelen = int((nx - noverlap) / (nwind - noverlap))
    return framelen

def Truelabel2Trueframe( TrueLabel_bin,wsize,wstep ):
    iidx = 0
    Frame_iidx = 0
    Frame_len = Frame_Length(TrueLabel_bin, wstep, wsize)
    Detect = np.zeros([Frame_len, 1])
    while 1 :
        if iidx+wsize <= len(TrueLabel_bin) :
            TrueLabel_frame = TrueLabel_bin[iidx:iidx + wsize - 1]*10
        else:
            TrueLabel_frame = TrueLabel_bin[iidx:]*10

        if (np.sum(TrueLabel_frame) >= wsize / 2) :
            TrueLabel_frame = 1
        else :
            TrueLabel_frame = 0

        if (Frame_iidx >= len(Detect)):
            break

        Detect[Frame_iidx] = TrueLabel_frame
        iidx = iidx + wstep
        Frame_iidx = Frame_iidx + 1
        if (iidx > len(TrueLabel_bin)):
            break

    return Detect

def binary_saver(name_file, data, num_file ):
    bin_num = '%3.3d'%num_file
    mrcg_name = name_file + '_'+bin_num+'.bin'
    spec_name = name_file + '_spec_' + bin_num+'.txt'
    fid_file = open(mrcg_name,'wb')
    fid_txt = open(spec_name,'wt')
    data.tofile(fid_file)
    nc, nr = np.shape(data)
    fid_txt.write(str(nc)+','+str(nr)+',float32')
    fid_file.close()
    fid_txt.close()
    return fid_file, fid_txt

def extract_MRCG(data_dir,save_dir):
    # Directory setting:
    os.system("mkdir " + save_dir + r'\Normalize_Factor')
    os.system("mkdir " + save_dir + r'\Labels')

    # Parameter setting:
    audio_sr = 16000
    split_num = 1
    name_mrcg = save_dir+r'\se_mrcg'
    name_label = save_dir+ r'\se_label'

    # Get all files in data_dir
    audio_list = [f for f in os.listdir(data_dir) if f.endswith('.wav')]
    label_list = [f for f in os.listdir(data_dir) if f.endswith('.mat')]

    winlen = int(np.ceil(audio_sr * 25 * 0.001))  # window length (default: 25 ms)
    winstep = int(np.ceil(audio_sr * 10 * 0.001)) # window step (default: 10 ms)

    train_mean = 0
    train_std = 0

    for i in range(len(audio_list)):
        # Read audio:
        noisy_speech, audio_sr = librosa.load(data_dir+'\\'+audio_list[i], sr=16000)
        print('Extracting MRCG features')
        mrcg_mat = np.transpose(mrcg.mrcg_features(noisy_speech, audio_sr))

        # Save normalization factor:
        temp_mean = np.mean(mrcg_mat, 0)
        temp_std = np.std(mrcg_mat, 0)
        sio.savemat(save_dir + r'\Normalize_Factor\normalize_factor_'+str(i), {'train_mean': temp_mean, 'train_std': temp_std})
        train_mean += temp_mean
        train_std += temp_std

        # Read label:
        label = sio.loadmat(data_dir+'\\'+label_list[i])['y_label']

        # Save framed label & MRCG:
        framed_label = Truelabel2Trueframe(label, winlen, winstep)

        if (len(mrcg_mat) > len(framed_label)):
            binary_saver(name_mrcg, mrcg_mat[0: len(framed_label), :], i)
            binary_saver(name_label, framed_label, i)
        else:
            binary_saver(name_mrcg, mrcg_mat, i)
            binary_saver(name_label, framed_label[1: len(mrcg_mat), 1], i)

        print('MRCG extraction done.')

    # Save global normalization factor:
    global_mean = train_mean / len(audio_list)
    global_std = train_std / len(audio_list)
    sio.savemat(save_dir + r'\global_normalize_factor',{'global_mean': global_mean, 'global_std': global_std})

    # Move label data:
    feat_list = [f for f in os.listdir(save_dir)]
    for i in range(len(feat_list)):
        if 'label' in feat_list[i]:
            (name, ext) = os.path.splitext(feat_list[i])
            new_path = save_dir+'\\Labels\\'+name+ext
            os.rename(save_dir+'\\'+feat_list[i], new_path)

def extract_feats(prj_dir,data_dir,save_dir,feats=0,feats_name='mrcg'):
    # Directory setting:
    os.system("mkdir " + save_dir + r'\Normalize_Factor')
    os.system("mkdir " + save_dir + r'\Labels')

    # Parameter setting:
    audio_sr = 16000
    split_num = 1
    name_feat = save_dir+r'\se_'+feats_name
    name_label = save_dir+ r'\se_label'

    # Get all files in data_dir
    audio_list = [f for f in os.listdir(data_dir) if f.endswith('.wav')]
    label_list = [f for f in os.listdir(data_dir) if f.endswith('.mat')]


    winlen = int(np.ceil(audio_sr * 25 * 0.001))  # window length (default: 25 ms)
    winstep = int(np.ceil(audio_sr * 10 * 0.001)) # window step (default: 10 ms)

    train_mean = 0
    train_std = 0

    if feats == 3:
        eng = matlab.engine.start_matlab()
        eng.addpath(prj_dir + r'\\lib\\data_prep\\rastamat', nargout=0)
    elif feats == 6:
        eng = matlab.engine.start_matlab()
        eng.addpath(prj_dir + r'\\lib\\data_prep', nargout=0)

    for i in range(len(audio_list)):
        # Read audio:
        noisy_speech, audio_sr = librosa.load(data_dir+'\\'+audio_list[i], sr=16000)
        print('Extracting '+feats_name+' features')
        if feats == 0:  # MRCG
            feats_mat = np.transpose(mrcg.mrcg_features(noisy_speech, audio_sr))
        elif feats == 1:  # MFCC
            mfcc = librosa.feature.mfcc(y=noisy_speech, sr=audio_sr, n_mfcc=40,hop_length=winstep,n_fft=winlen)
            delta1 = librosa.feature.delta(mfcc)
            delta2 = librosa.feature.delta(mfcc, order=2)
            feats_mat = np.transpose(np.concatenate((mfcc, delta1, delta2), axis=0))
            feats_mat = np.float64(feats_mat)
        # elif feats == 2: # MRACC
        #     bin_num = '%3.3d' % i
        #     name_mrcg = save_dir.replace('mracc', 'mrcg') + r'\se_mrcg'
        #     bin_name = name_mrcg + '_' + bin_num + '.bin'
        #     spec_name = name_mrcg + '_spec_' + bin_num + '.txt'
        #     feats_mat = np.transpose(mracc.mracc_features(noisy_speech, audio_sr, bin_name, spec_name))
        elif feats == 2: # AMS
            ams = ams_ex.get_ams(noisy_speech, audio_sr)
            delta1 = librosa.feature.delta(ams)
            delta2 = librosa.feature.delta(ams, order=2)
            feats_mat = np.transpose(np.concatenate((ams, delta1, delta2), axis=0))
        elif feats == 3: # rasta-plp
            noisy_speech = matlab.double([noisy_speech.tolist()])
            audio_sr = matlab.double([audio_sr])
            rplp = eng.rastaplp(noisy_speech, audio_sr, 1, 18)
            rplp = np.array(rplp[1:])
            delta1 = librosa.feature.delta(rplp)
            delta2 = librosa.feature.delta(rplp, order=2)
            feats_mat = np.transpose(np.concatenate((rplp, delta1, delta2), axis=0))
            #lpcas = rsta_plp.rplp_ex(noisy_speech, audio_sr, 18)
            #feats_mat = np.transpose(lpcas)
        elif feats == 4: # mr-mfcc
            feats_mat = np.transpose(mr_mfcc.mr_mfcc_ex(noisy_speech, audio_sr))
            feats_mat = np.float64(feats_mat)
        # elif feats == 6: # log spectrum
        #     feats_mat = np.transpose(mel_spec.mel_spectrogram_features(noisy_speech, audio_sr, winstep, winlen))
        elif feats == 5: # gfcc
            feats_mat = np.transpose(gfcc.gfcc_ex(noisy_speech, audio_sr))
        elif feats == 6: # eng_zc
            noisy_speech = matlab.double([noisy_speech.tolist()])
            audio_sr = matlab.double([audio_sr])
            feats_mat = np.array(eng.eng_zc(noisy_speech, audio_sr, matlab.double([winlen]), matlab.double([winstep])))



        # Save normalization factor:
        temp_mean = np.mean(feats_mat, 0)
        temp_std = np.std(feats_mat, 0)
        sio.savemat(save_dir + r'\Normalize_Factor\normalize_factor_'+str(i), {'train_mean': temp_mean, 'train_std': temp_std})
        train_mean += temp_mean
        train_std += temp_std

        # Read label:
        label = sio.loadmat(data_dir+'\\'+label_list[i])['y_label']

        # Save framed label & feature:
        framed_label = Truelabel2Trueframe(label, winlen, winstep)

        if len(feats_mat) > len(framed_label):
            binary_saver(name_feat, feats_mat[0: len(framed_label), :], i)
            binary_saver(name_label, framed_label, i)
        else:
            binary_saver(name_feat, feats_mat, i)
            binary_saver(name_label, framed_label[0: len(feats_mat)], i)

        print('Feature extraction done.')

    # Save global normalization factor:
    global_mean = train_mean / len(audio_list)
    global_std = train_std / len(audio_list)
    sio.savemat(save_dir + r'\global_normalize_factor.mat',{'global_mean': global_mean, 'global_std': global_std})

    # Move label data:
    feat_list = [f for f in os.listdir(save_dir)]
    for i in range(len(feat_list)):
        if 'label' in feat_list[i]:
            (name, ext) = os.path.splitext(feat_list[i])
            new_path = save_dir+'\\Labels\\'+name+ext
            os.rename(save_dir+'\\'+feat_list[i], new_path)

'''function
acoustic_feat_ex(data_dir, save_dir)

rng(0);
% % Directory


% system(['rm -rf ', save_dir]);
%
% system(['mkdir ', save_dir]);
system(['mkdir ', save_dir, '/Normalize_Factor']);
system(['mkdir ', save_dir, '/Labels']);

% % Parameter
setting

audio_sr = 16000;
split_num = 1;
name_mrcg = [save_dir, '/se_mrcg'];
name_label = [save_dir, '/se_label'];

audio_list = getAllFiles(data_dir, 'FileFilter', '\.wav$');
label_list = getAllFiles(data_dir, 'FileFilter', '\.mat$');

winlen = ceil(audio_sr * 25 * 0.001); % window
length(default: 25
ms)
winstep = ceil(audio_sr * 10 * 0.001); % window
step(default: 10
ms)

train_mean = 0;
train_std = 0;

for i = 1:1:length(audio_list)
clc
fprintf("MRCG extraction %d/%d ...\n", i, length(audio_list));
% % Read
audio

noisy_speech = audioread(audio_list
{i}); % noisy_speech
load
noisy_speech = noisy_speech(1:(length(noisy_speech) - mod(length(noisy_speech), split_num)));
noisy_speech = reshape(noisy_speech, [], split_num);

% % Caliculate
MRCG
mrcg = cell(split_num, 1);

for j = 1:1:split_num
mrcg
{j, 1} = MRCG_features(noisy_speech(:, j), audio_sr)';
% imagesc(s(20000:20500,:)*1000)
end

mrcg_mat = cell2mat(mrcg);

size(mrcg_mat)
% % Save
normalization
factor

temp_mean = mean(mrcg_mat, 1);
temp_std = std(mrcg_mat, 1, 1);
save([save_dir, '/Normalize_Factor/normalize_factor_', sprintf('%3.3d', i)], 'temp_mean', 'temp_std');
train_mean = temp_mean + train_mean;
train_std = temp_std + train_std;

% % Read
label
label = cell2mat(struct2cell(load(label_list
{i}))); % label
load

% % Save
framed
label & MRCG
framed_label = Truelabel2Trueframe(label, winlen, winstep);
length(framed_label)
if (length(mrcg_mat) > length(framed_label))
    binary_saver(name_mrcg, mrcg_mat(1:length(framed_label),:), i );
    binary_saver(name_label, framed_label, i);
else
    binary_saver(name_mrcg, mrcg_mat, i);
    binary_saver(name_label, framed_label(1:length(mrcg_mat), 1), i );
    end
end

disp('MRCG extraction done.')
% % Save
global normalization
factor

global_mean = train_mean / length(audio_list);
global_std = train_std / length(audio_list);
save([save_dir, '/global_normalize_factor'], 'global_mean', 'global_std');

% % Move
label
data

feat_list = getAllFiles(save_dir);

for i=1:1:length(feat_list)
if ~isempty(strfind(feat_list{i}, 'label'))
[pathstr, name, ext] = fileparts(feat_list
{i});
new_path = [pathstr, '/Labels/', name, ext];
movefile(feat_list
{i}, new_path);
end
end

end'''