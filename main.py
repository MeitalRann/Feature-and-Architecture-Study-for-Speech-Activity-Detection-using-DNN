import librosa
import librosa
import numpy as np
import matplotlib.pyplot as plt

#import lib.matlab_py.utils as utils
import lib.python.test_utils as utils
import lib.python.feat_setting as fs

audio_dir = r'.\data\example\clean_speech.wav'
prj_dir = r'C:\meital\University\Madison\Thesis\VAD-py'

mode = 0
th = 0.5
f = 3

set_feat = fs.featSetting(f)
f_name = set_feat.name

output_type = 1
is_default = 1

#result = utils.vad_func(audio_dir, mode, th, output_type, is_default, off_on_length=20, on_off_length=20,
#                        hang_before=20, hang_over=20)
result = utils.vad_func(prj_dir, audio_dir, mode, th, output_type, is_default, f, f_name, off_on_length=20, on_off_length=20,
                        hang_before=20, hang_over=20)

s, audio_sr = librosa.load(audio_dir, sr=16000)

t_max = np.minimum(s.shape[0], result.shape[0])

t = np.arange(0, t_max) / audio_sr
s = np.divide(s, np.max(np.absolute(s)))

result = np.multiply(result, 0.3)
plt.plot(t, s[0:t_max], 'b')
plt.plot(t, result, 'g')
plt.show()
