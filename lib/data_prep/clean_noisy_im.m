close all;
clean_file = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\clean\timit_test001.wav';
label_file = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\clean\timit_test001.mat';
noise_file = 'C:\meital\University\Madison\Thesis\VAD-py\data\raw\noise\test\matched\noise_test001.wav';

st = 1;
nd = 2.5;
Fs = 16000;
m = 'dSbeEtK';
snr = -5;

[clean, fs] = audioread(clean_file);
[noise, fs] = audioread(noise_file);

clean = clean(st*Fs+1:nd*Fs)';
noise = noise(st*Fs+1:nd*Fs)';
t = 0:1/Fs:(length(clean)-1)/Fs;

noisy_speech = v_addnoise(clean,Fs,snr,m,noise);

load(label_file);
y_label = y_label(st*Fs+1:nd*Fs)';

figure;
subplot(2,1,1);
plot(t,clean); title('Clean Speech');
xlabel('Time [s]');
% hold on; plot(t,0.2*y_label)
subplot(2,1,2);
plot(t,noisy_speech); title('Noisy Speech (SNR=-5dB)');
xlabel('Time [s]');
