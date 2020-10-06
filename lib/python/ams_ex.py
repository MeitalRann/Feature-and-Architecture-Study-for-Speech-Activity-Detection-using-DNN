import math
from scipy.signal import butter, lfilter, decimate
import numpy as np
from feature_extractor import stft_extractor

# Meital's version:
# Based on the papers:
# 1. "An algorithm that improves speech intelligibility in noise for normal-hearing listeners"
# 2. "Deep Neural Networks for Multi-Room Voice Activity Detection: Advancements and Comparative Evaluation"

def mel(N,low,high):
    # This function returns the lower, center and upper freqs of the filters equally spaced in mel - scale
    # Input: N - number of filters
    #        low - (left - edge)3dB point of the first filter
    #        high - (right - edge)3dB point of the last filter
    ac = 1000
    fc = 800

    LOW = ac * np.log(1 + low / fc)
    HIGH = ac * np.log(1 + high / fc)
    N1 = N + 1

    fmel=LOW + range(1,N1+1)*(HIGH - LOW) / N1
    cen2 = [fc * (math.exp (fmel[i] / ac) - 1) for i in range(N1)]
    # cen2 = fc * (math.exp (fmel / ac) - 1)

    lower=cen2[0: N]
    upper=cen2[1: N + 1]
    center= [0.5 * (lower[i] + upper[i])  for i in range(N)]
    return lower, upper

def butter_bandpass(lowcut, highcut, fs, order=5):
    nyq = 0.5 * fs
    if highcut >= nyq:
        highcut -= 50
    low = lowcut / nyq
    high = highcut / nyq

    b, a = butter(order, [low, high], btype='bandpass')
    return b, a


def butter_bandpass_filter(data, lowcut, highcut, fs, order=5):
    b, a = butter_bandpass(lowcut, highcut, fs, order=order)
    y = lfilter(b, a, data)
    return y

def envelope(sig, choice='abs'):
    R = 4    # decimation factor, R times shorter
    if choice == 'abs':
        ENV = abs(sig)
    elif choice == 'square':
        ENV = abs(sig ** 2)
    env = decimate(ENV, R, ftype='fir')
    return env

def tri_win(nFFT_ams):
    # create 15 triangular windows spaced uniformly
    MF_T = np.zeros((15, nFFT_ams // 2+1))
    MF_T[0, 1 : 1 + 3] = [0.25, 0.5, 0.25]
    MF_T[1, 2: 1 + 5] = [0.1, 0.4, 0.4, 0.1]
    MF_T[2, 3: 1 + 6] = [0.1, 0.4, 0.4, 0.1]
    MF_T[3, 4: 1 + 6] = [0.25, 0.5, 0.25]
    MF_T[4, 4: 1 + 7] = [0.1, 0.4, 0.4, 0.1]
    MF_T[5, 5: 1 + 8] = [0.1, 0.4, 0.4, 0.1]
    MF_T[6, 6: 1 + 9] = [0.1, 0.4, 0.4, 0.1]
    MF_T[7, 8: 1 + 10] = [0.25, 0.5, 0.25]
    MF_T[8, 9: 1 + 12] = [0.1, 0.4, 0.4, 0.1]
    MF_T[9, 11: 1 + 13] = [0.25, 0.5, 0.25]
    MF_T[10, 13: 1 + 15] = [0.25, 0.5, 0.25]
    MF_T[11, 15: 1 + 17] = [0.25, 0.5, 0.25]
    MF_T[12, 17: 1 + 19] = [0.25, 0.5, 0.25]
    MF_T[13, 20: 1 + 22] = [0.25, 0.5, 0.25]
    MF_T[14, 23: 1 + 25] = [0.25, 0.5, 0.25]
    return MF_T

def get_ams(speech, audio_sr,N=9):
    frame_len = 25  # 25ms. frame step is 10ms
    env_step = 0.25
    len2 = env_step * audio_sr // 1000
    Nframes = len(speech) // len2
    Srate_env = 1 / (env_step / 1000)
    nFFT_ams = 256
    AMS_frame_len = frame_len // env_step # 100 frames of envelope corresponding to 100 * 0.25 = 25ms
    AMS_frame_step = 80 // 2 # step size, corresponds to 40 frames of envelope, i.e. 10ms window shift in orignal signal
    KK = Nframes // AMS_frame_step - 1 # number of frames

    # step 1: do 9 filter bands (mel scale)
    lower,upper = mel(N, 0, audio_sr/2)
    bp_signal = np.ndarray(shape=(N,len(speech)), dtype='float64')
    for i in range(N):
        l = lower[i]
        u = upper[i]
        y = butter_bandpass_filter(speech, l, u, audio_sr, 6)
        bp_signal[i] = y

    # for each channel:
    AMS = np.ndarray(shape=(N,15,int(KK)), dtype='float64')
    once = True
    for i in range(N):
        bp_i = bp_signal[i]
        # step 2: get envelope + decimation:
        env = envelope(bp_i)
        # step 3: framing and fft:
        s_f = np.abs(stft_extractor(env, int(AMS_frame_len), int(AMS_frame_step), 'hanning', n_fft=nFFT_ams),dtype='float64')
        if np.shape(s_f)[1] != np.shape(AMS)[2] and once:
            KK = np.shape(s_f)[1]
            AMS = np.ndarray(shape=(N,15,int(KK)), dtype='float64')
            once = False
        t_w = tri_win(nFFT_ams)
        ams = np.matmul(t_w,s_f)
        AMS[i] = ams

    AMS = np.reshape(AMS,(N*15,int(KK)))
    return AMS
