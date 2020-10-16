import numpy as np
import sys
import os, getopt
import scipy.io as sio
from sklearn.metrics import accuracy_score

sys.path.insert(0, r'.\lib\python')
import eer_test as err_test
import feat_setting as fs
import test_utils as utils



if __name__ == '__main__':

    try:
        opts, args = getopt.getopt(sys.argv[1:], 'hm:e:f:', ["prj_dir="])
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(1)

    if len(opts) != 4:
        print("arguments are not enough.")
        sys.exit(1)

    for opt, arg in opts:
        if opt == '-h':
            sys.exit(0)
        elif opt == '-m':
            mode = int(arg)
        elif opt == '-e':
            extract_feat = int(arg)
        elif opt == '--prj_dir':
            prj_dir = str(arg)
        elif opt == '-f':
            feat = int(arg)

    set_feat = fs.featSetting(feat)
    f_name = set_feat.name
    f_dim = set_feat.dimension

    output_type = 0
    is_default = 0
    th = 0.5

    if mode == 0:
        mode_name = 'ACAM'
    elif mode == 1:
        mode_name = 'bDNN'
    elif mode == 2:
        mode_name = 'DNN'
    elif mode == 3:
        mode_name = 'LSTM'


    try:
        os.remove(prj_dir + r'\\result\\' + mode_name + r'\\' + f_name + r'\AUC.txt')
    except:
        print("Error while deleting file ", prj_dir + r'\\result\\' + mode_name + r'\\' + f_name + r'\AUC.txt')
        try:
            print('Create ', prj_dir + r'\\result\\' + mode_name + r'\\' + f_name)
            os.makedirs(prj_dir + r'\\result\\' + mode_name + r'\\' + f_name)
        except:
            print(prj_dir + r'\\result\\' + mode_name + r'\\' + f_name, 'Exists')

    train_dir = prj_dir + r"\data\raw\test"
    dir_list = list_subfolders_with_paths = [f.path for f in os.scandir(train_dir) if f.is_dir()]

    for n in range(len(dir_list)):
        folder = dir_list[n]
        subfolders = [f.name for f in os.scandir(folder) if f.is_dir()]
        for dir in subfolders:
            dir_name = dir
            test_dir = folder + r'\\' + dir
            tot_auc = utils.vad_func(prj_dir, test_dir, mode, th, extract_feat, is_default, feat, f_name, dir_name,
                                     off_on_length=30,
                                     on_off_length=30, hang_before=0, hang_over=0)
            print(tot_auc)
            with open(prj_dir + r'\\result\\' + mode_name + r'\\' + f_name + r'\AUC.txt', 'a') as the_file:
                the_file.write(dir_name + ':  ' + str(tot_auc) + ' \n')
        if len(subfolders) == 0:
            test_dir = folder
            dir_name = folder.split('\\')[-1]
            tot_auc = utils.vad_func(prj_dir, test_dir, mode, th, extract_feat, is_default, feat, f_name, dir_name,
                                     off_on_length=30,
                                     on_off_length=30, hang_before=0, hang_over=0)
            print(tot_auc)
            with open(prj_dir + r'\\result\\' + mode_name + r'\\' + f_name + r'\AUC.txt', 'a') as the_file:
                the_file.write(dir_name + ':  ' + str(tot_auc) + ' \n')




    # # noise independent testset:
    # folder = r'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\noisy'
    # subfolders = [f.name for f in os.scandir(folder) if f.is_dir()]
    # for dir in subfolders:
    #     dir_name = dir
    #     test_dir = folder + r'\\' + dir
    #     tot_auc = utils.vad_func(prj_dir, test_dir, mode, th, extract_feat, is_default, feat, f_name, dir_name, off_on_length=30,
    #                              on_off_length=30, hang_before=0, hang_over=0)
    #     print(tot_auc)
    #     with open(prj_dir + r'\\result\\' + mode_name + r'\\' + f_name + r'\AUC.txt', 'a') as the_file:
    #         the_file.write(dir_name + ':  ' + str(tot_auc) + ' \n')
    #
    #
    # # recorded testset:
    # folder = r'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\recorded_data'
    # subfolders = [f.name for f in os.scandir(folder) if f.is_dir()]
    # for dir in subfolders:
    #     dir_name = dir
    #     test_dir = folder + r'\\' + dir
    #     tot_auc = utils.vad_func(prj_dir, test_dir, mode, th, extract_feat, is_default, feat, f_name, dir_name, off_on_length=30,
    #                              on_off_length=30, hang_before=0, hang_over=0)
    #     print(tot_auc)
    #     with open(prj_dir + r'\\result\\' + mode_name + r'\\' + f_name + r'\AUC.txt', 'a') as the_file:
    #         the_file.write(dir_name + ':  ' + str(tot_auc) + ' \n')
    #
    # # noise dependent testset:
    # dir_name = 'matched'
    # test_dir = r'C:\meital\University\Madison\Thesis\VAD-py\data\raw\test\matched'
    # tot_auc = utils.vad_func(prj_dir, test_dir, mode, th, extract_feat, is_default, feat, f_name, dir_name, off_on_length=30,
    #                         on_off_length=30, hang_before=0, hang_over=0)
    # print(tot_auc)
    # with open(prj_dir + r'\\result\\' + mode_name + r'\\' + f_name + r'\AUC.txt', 'a') as the_file:
    #     the_file.write(dir_name + ':  ' + str(tot_auc) + ' \n')
