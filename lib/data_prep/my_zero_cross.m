function zc = my_zero_cross(signal,Fs, win_len, hop_len)

frames = v_enframe(signal,win_len,hop_len,'z',Fs);
[m,n] = size(frames);
zc = zeros(m,1);
for i=1:m
    t = v_zerocros(frames(i,:));
    zc(i) = length(t);
end