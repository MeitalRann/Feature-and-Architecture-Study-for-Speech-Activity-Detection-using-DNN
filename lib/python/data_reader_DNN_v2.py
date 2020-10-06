import numpy as np
import os
import glob
import utils
import scipy.io as sio
import matplotlib.pyplot as plt
import matplotlib.image as mpimg


class DataReader(object):

    def __init__(self, input_dir, output_dir, norm_dir, w=19, u=9, name=None, st=0):
        # print(name.title() + " data reader initialization...")
        self._input_dir = input_dir
        self._output_dir = output_dir
        self._norm_dir = norm_dir
        self._input_file_list = sorted(glob.glob(input_dir+'/*.bin'))[st:]
        self._input_spec_list = sorted(glob.glob(input_dir+'/*.txt'))[st:]
        self._output_file_list = sorted(glob.glob(output_dir+'/*.bin'))[st:]
        self._file_len = len(self._input_file_list)
        self._name = name
        assert self._file_len == len(self._output_file_list), "# input files and output file is not matched"
        self._w = w
        self._u = u
        self.eof = False
        self.file_change = False
        self.num_samples = 0

        self._inputs = 0
        self._outputs = 0

        self._epoch = 1
        self._num_file = 0
        self._start_idx = self._w

        norm_param = sio.loadmat(self._norm_dir+'/global_normalize_factor.mat')
        self.train_mean = norm_param['global_mean']
        self.train_std = norm_param['global_std']
        self.raw_inputs = 0  # adding part

        # print("Done")
        # print("BOF : " + self._name + " file_" + str(self._num_file).zfill(2))

    def _binary_read_with_shape(self):
        pass

    @staticmethod
    def _read_input(input_file_dir, input_spec_dir):
        print(input_file_dir)
        data = np.fromfile(input_file_dir)  # (# total frame, feature_size)
        with open(input_spec_dir,'r') as f:
            spec = f.readline()
            size = spec.split(',')
        # data = data.reshape((int(size[0]), int(size[1])), order='F')
        data = data.reshape((int(size[0]), int(size[1])))

        return data

    @staticmethod
    def _read_output(output_file_dir):
        print(output_file_dir)
        data = np.fromfile(output_file_dir)  # data shape : (# total frame,)
        data = data.reshape(-1, 1)  # data shape : (# total frame, 1)

        return data

    @staticmethod
    def _padding(inputs, batch_size, w_val):
        print(inputs.shape[0])
        pad_size = batch_size - inputs.shape[0] % batch_size

        inputs = np.concatenate((inputs, np.zeros((pad_size, inputs.shape[1]), dtype=np.float32)))

        window_pad = np.zeros((w_val, inputs.shape[1]))
        inputs = np.concatenate((window_pad, inputs, window_pad), axis=0)
        return inputs

    def next_batch(self, batch_size):

        if self._start_idx == self._w:
            self._inputs = self._padding(
                self._read_input(self._input_file_list[self._num_file],
                                 self._input_spec_list[self._num_file]), batch_size, self._w)
            self._outputs = self._padding(self._read_output(self._output_file_list[self._num_file]), batch_size, self._w)
            assert np.shape(self._inputs)[0] == np.shape(self._outputs)[0], \
                ("# samples is not matched between input: %d and output: %d files"
                 % (np.shape(self._inputs)[0], np.shape(self._outputs)[0]))

            self.num_samples = np.shape(self._outputs)[0]

        if self._start_idx + batch_size > self.num_samples:

            self._start_idx = self._w
            self.file_change = True
            self._num_file += 1

            # print("EOF : " + self._name + " file_" + str(self._num_file-1).zfill(2) +
            #       " -> BOF : " + self._name + " file_" + str(self._num_file).zfill(2))

            if self._num_file > self._file_len - 1:
                self.eof = True
                self._num_file = 0
                # print("EOF : last " + self._name + " file. " + "-> BOF : " + self._name + " file_" +
                #       str(self._num_file).zfill(2))

            self._inputs = self._padding(
                self._read_input(self._input_file_list[self._num_file],
                                 self._input_spec_list[self._num_file]), batch_size, self._w)

            self._outputs = self._padding(self._read_output(self._output_file_list[self._num_file]), batch_size, self._w)

            data_len = np.shape(self._inputs)[0]
            self._outputs = self._outputs[0:data_len, :]

            assert np.shape(self._inputs)[0] == np.shape(self._outputs)[0], \
                ("# samples is not matched between input: %d and output: %d files"
                 % (np.shape(self._inputs)[0], np.shape(self._outputs)[0]))

            self.num_samples = np.shape(self._outputs)[0]

        else:
            self.file_change = False
            self.eof = False


        inputs = self._inputs[self._start_idx - self._w:self._start_idx + batch_size + self._w, :]
        self.raw_inputs = inputs  # adding part
        inputs = self.normalize(inputs)
        inputs = utils.bdnn_transform(inputs, self._w, self._u)
        inputs = inputs[self._w: -self._w, :]

        outputs = self._outputs[self._start_idx:self._start_idx + batch_size, :]

        self._start_idx += batch_size

        return inputs, outputs

        #num_batches = (np.shape(self._outputs)[0] - np.shape(self._outputs)[0] % batch_size) / batch_size
    def normalize(self, x):
        x = (x - self.train_mean)/self.train_std
        # a = (np.std(x, axis=0))
        return x

    def reader_initialize(self):
        self._num_file = 0
        self._start_idx = 0
        self.eof = False

    def eof_checker(self):
        return self.eof

    def file_change_checker(self):
        return self.file_change

    def file_change_initialize(self):
        self.file_change = False


def dense_to_one_hot(labels_dense, num_classes=2):
    """Convert class labels from scalars to one-hot vectors."""
    # copied from TensorFlow tutorial
    num_labels = labels_dense.shape[0]
    index_offset = np.arange(num_labels) * num_classes
    labels_one_hot = np.zeros((num_labels, num_classes))
    labels_one_hot.flat[index_offset + labels_dense.ravel()] = 1
    return labels_one_hot


# file_dir = "/home/sbie/github/VAD_KJT/Datamake/Database/Aurora2withSE"
# input_dir1 = file_dir + "/STFT2"
# output_dir1 = file_dir + "/Labels"
# dr = DataReader(input_dir1, output_dir1, input_dir1,name='test')
#
# for i in range(1000000):
#     tt, pp = dr.next_batch(500)
#     print("asdf")



