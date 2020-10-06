
class featSetting(object):

    def __init__(self, f):
        if f == 0:
            name = 'mrcg'
            dim = 768
        elif f == 1:
            name = 'mfcc'
            dim = 120
        # elif f == 2:
        #     name = 'mracc'
        #     dim = 432
        elif f == 2:
            name = 'ams'
            dim = 405
        elif f == 3:
            name = 'rasta_plp'
            dim = 54
        elif f == 4: # MR-MFCC
            name = 'mr_mfcc'
            dim = 240
        # elif f == 6:
        #     name ='mel_spectrogram'
        #     dim = 384
        elif f == 5:
            name = 'gfcc'
            dim = 120
        elif f == 6:
            name = 'eng_zc'
            dim = 6

        self.name = name
        self.dimension = dim
