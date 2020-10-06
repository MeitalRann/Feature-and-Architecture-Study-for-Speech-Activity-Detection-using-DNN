function [subDirsNames] = GetSubDirs(parentDir)

% Get a list of all files and folders in this folder (first level only).
files    = dir(parentDir);
names    = {files.name};
% Get a logical vector that tells which is a directory.
dirFlags = [files.isdir] & ~strcmp(names, '.') & ~strcmp(names, '..');
% Extract only those that are directories.
subDirsNames = names(dirFlags);
end