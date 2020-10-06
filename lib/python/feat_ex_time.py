import time
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

# Parameters:
data_dir = r'C:\meital\University\Madison\Thesis\VAD-py\data\raw\train'

# Get all files in data_dir
audio_list = [f for f in os.listdir(data_dir) if f.endswith('.wav')]
label_list = [f for f in os.listdir(data_dir) if f.endswith('.mat')]

try:
    os.remove('feat_ex_time.txt')
except:
    print("Error while deleting file: feat_ex_time.txt")

audio_sr = 16000
n_files = 100

winlen = int(np.ceil(audio_sr * 25 * 0.001))  # window length (default: 25 ms)
winstep = int(np.ceil(audio_sr * 10 * 0.001)) # window step (default: 10 ms)

feat_list = ['mrcg', 'mfcc', 'ams', 'mr_mfcc', 'gfcc']

for f in range(5):
    tot_time = 0
    for i in range(n_files): # average over 100 files
        # Read audio:
        noisy_speech, audio_sr = librosa.load(data_dir+'\\'+audio_list[i], sr=16000)
        start_time = time.time()
        if f == 0:  # MRCG
            feats_mat = np.transpose(mrcg.mrcg_features(noisy_speech, audio_sr))
        elif f == 1:  # MFCC
            mfcc = librosa.feature.mfcc(y=noisy_speech, sr=audio_sr, n_mfcc=40,hop_length=winstep,n_fft=winlen)
            delta1 = librosa.feature.delta(mfcc)
            delta2 = librosa.feature.delta(mfcc, order=2)
            feats_mat = np.transpose(np.concatenate((mfcc, delta1, delta2), axis=0))
            feats_mat = np.float64(feats_mat)
        elif f == 2: # AMS
            ams = ams_ex.get_ams(noisy_speech, audio_sr)
            delta1 = librosa.feature.delta(ams)
            delta2 = librosa.feature.delta(ams, order=2)
            feats_mat = np.transpose(np.concatenate((ams, delta1, delta2), axis=0))
        elif f == 3: # mr-mfcc
            feats_mat = np.transpose(mr_mfcc.mr_mfcc_ex(noisy_speech, audio_sr))
            feats_mat = np.float64(feats_mat)
        elif f == 4: # gfcc
            feats_mat = np.transpose(gfcc.gfcc_ex(noisy_speech, audio_sr))

        elapsed_time = time.time() - start_time
        tot_time += elapsed_time

    with open(r'feat_ex_time.txt', 'a') as the_file:
        the_file.write(feat_list[f] + ':  ' + str(tot_time/n_files) + ' \n')
