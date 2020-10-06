function run_feat_ex(data_dir,save_dir, f, f_name)
system(['rmdir ', save_dir, ' /S /Q']);
system(['mkdir ' , save_dir]);

audio_list = getAllFiles(data_dir, 'FileFilter', '\.wav$');

for i = 1:length(audio_list)
    audio_dir = cell2mat(audio_list(i));
    save_dir_i = [save_dir , '\' , num2str(i-1)];
    system(['mkdir ' , save_dir_i]);
    test_feat_extract(audio_dir, f, f_name, save_dir_i);
end
end