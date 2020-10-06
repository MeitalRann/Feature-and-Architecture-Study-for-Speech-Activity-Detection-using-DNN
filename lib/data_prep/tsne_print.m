close all;
% Create t-sne images of all 6th features:
feat_dir = 'C:\meital\University\Madison\Thesis\VAD-py\sample_data\park\feat\1\';
lab_dir = 'C:\meital\University\Madison\Thesis\VAD-py\sample_data\park\feat\1\Labels\';

feats = {'mrcg','mfcc','gfcc','ams','rasta_plp','mr_mfcc'};
figure;
for i=1:6
    feat_file = [strrep(feat_dir,'feat',cell2mat(feats(i))),cell2mat(feats(i)),'_000.bin'];
    fID = fopen(feat_file);
    F = fread(fID,'float64');
    spec_file = [strrep(feat_dir,'feat',cell2mat(feats(i))),cell2mat(feats(i)),'_spec_000.txt'];
    sID = fopen(spec_file,'r');
    formatSpec = '%d%c%d';
    A = fscanf(sID,formatSpec);
    m = A(1); n = A(3);
    F = vec2mat(F,n);
    F = F(:,1:n/3);
    
    lab_file = [strrep(lab_dir,'feat',cell2mat(feats(i))),'label_000.bin'];
    lID = fopen(lab_file);
    L = fread(lID,'float64');
    
    Y = tsne(F);
    subplot(3,2,i); gscatter(Y(:,1),Y(:,2),L,[],[],[],'off'); 
    lgd = legend('0','1');
    lgd.FontSize = 14;
    title(strrep(cell2mat(feats(i)),'_','-'));
    ax = gca;
    ax.FontSize = 14;
    fclose(fID); fclose(sID); fclose(lID);
end