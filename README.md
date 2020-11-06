# Feature and Architecture Study for Speech Activity Detection using DNN
This toolkit provides the code used in a Master's thesis (Feature and Architecture Study for Speech Activity Detection using Deep Neural Networks) at the University of Wisconsin-Madison, department of Electrical and Computer Engineering.

## Introduction

This Toolkit is based on the work done in: https://github.com/jtkim-kaist/VAD [1].

The added value of this toolkit is a feature analysis section.

The SAD in this toolkit follows the procedure as below:

#### Acoustic feature extraction
The following features are extracted from the speech using Python:
1. MRCG
2. MFCC
3. GFCC
4. RASTA-PLP (extracted in Matlab from Python)
5. AMS
6. Energy + Zero Crossing (extracted in Matlab from Python)
7. Multi-Resolusion MFCC- a new feature created for this thesis

##### Multi-Resolusion MFCC (MR-MFCC):

The main idea behind this feature was to encodes a multi-resolution spectral representation of the speech signal, to captures both the local information and the spectro-temporal contexts. This feature was inspired by the Multi-Resolution Cochleagram (MRCG), which was found to be beneficial for SAD, but follows an extraction scheme with less computational complexity.

The MR-MFCC is extracted in three steps: 
1. Compute a 40-dimension MFCC from 25ms windows 
2. Compute the MFCC from windows of length 200ms
3. Voncatenate the results to one vector to produce a feature with 80 dimensions. 

The step length was kept the same for both resolutions, at 10ms. 

The MFCC was chosen for its simplicity and superior performance for many speech applications.

#### Classifier

This toolkit supports 4 types of classifers implemented in python with tensorflow:
1. Adaptive context attention model (ACAM) [1]
2. Boosted deep neural network (bDNN) [2]
3. Deep neural network (DNN) [2] 
4. Long short term memory recurrent neural network (LSTM-RNN) [3]

## Prerequisites

- Python 3

- Tensorflow 1.1-3

- Matlab 2017b

## Data:
The data used in this project was created following the procedure in [1]. Example is avilable in the data directory. For data preperation code, see train_data_prep_2.m and test_data_prep_dep_2.m in lib/data_prep.

## Example

### Training:

For training, run the code train.py in the python directory. The following is the parameters' options:

```
# train.py
# train script options
# m 0 : ACAM
# m 1 : bDNN
# m 2 : DNN
# m 3 : LSTM
# f 0 : MRCG
# f 1 : MFCC
# f 2 : AMS
# f 3 : RASTA-PLP
# f 4 : MR-MFCC
# f 5 : gfcc
# f 6 : Energy+Zero-crossing
# e : extract feature (1) or not (0)
# r : retrain model (1) or not (0)

python3 $train.py -m 0 -f 0 -e 1 -r 0 --prj_dir=path/to/dir
```

Notes: 
1. To apply this toolkit to other speech data, the speech data should be sampled with 16kHz sampling frequency.
2. Do not forget to install Matlab's engine API for python. For more info see:
https://www.mathworks.com/help/matlab/matlab_external/install-the-matlab-engine-for-python.html


### Testing:

For testing, run the code test.py in the python directory. The following is the parameters' options:

```
# test.py
# test script options
# m 0 : ACAM
# m 1 : bDNN
# m 2 : DNN
# m 3 : LSTM
# f 0 : MRCG
# f 1 : MFCC
# f 2 : AMS
# f 3 : RASTA-PLP
# f 4 : MR-MFCC
# f 5 : gfcc
# f 6 : Energy+Zero-crossing
# e : extract feature (1) or not (0)

python3 $test.py -m 0 -f 0 -e 1 --prj_dir=path/to/dir
```


## License
MIT License

Copyright (c) [2020] [Meital Rannon]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


## References
[1] J. Kim and M. Hahn, "Voice Activity Detection Using an Adaptive Context Attention Model," in IEEE Signal Processing Letters, vol. 25, no. 8, pp. 1181-1185, 2018.

[2] Zhang, Xiao-Lei, and DeLiang Wang. “Boosting contextual information for deep neural network based voice activity detection,” IEEE Trans. Audio, Speech, Lang. Process., vol. 24, no. 2, pp. 252-264, 2016.

[3] Zazo Candil, Ruben, et al. “Feature learning with raw-waveform CLDNNs for Voice Activity Detection.”, 2016.
