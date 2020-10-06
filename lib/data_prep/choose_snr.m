function snr = choose_snr(snr_list,num_files,file_i)

if snr_list(end)>snr_list(1)
    snr_list = flip(snr_list);
end

a = num_files/length(snr_list);

if a == 1
    if file_i <= length(snr_list)
        snr = snr_list(file_i);
    else 
        rand_ind = randi(length(snr_list), 1);
        snr = snr_list(rand_ind);
    end
else
    sections = a:a:num_files;
    add = num_files - sections(end);
    sections = sections+add;

    for i = 1:length(sections)
        if file_i <= sections(i)
            snr = snr_list(i);
            break
        end
    end
end