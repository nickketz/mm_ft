function locked = lockFile(filename, overwrite)
%LOCKFILE - Check if file exists, locking it if not.
%
% This function helps to keep multiple procs from working on the same
% file when on a cluster.  It will make sure that the file does not
% already exist and then touch that file and create a matching lock
% file that will prevent others from working on that file.
%
% Be sure to release the file with releaseFile when you are done.
%
% FUNCTION:
%   locked = lockFile(filename)
%
% INPUT ARGS:
%   filename- The file to test/touch.
%
% OUTPUT ARGS:
%   locked- 1 if we created/locked the file and are responsible for it
%
%
% Attribution: Borrowed from the Kahana Lab's eeg_toolbox

if ~exist('overwrite', 'var')
  overwrite = 0;
end

% test name
lockname = [filename '.lock'];

% if overwriting not allowed, first see if file exists
if ~overwrite && exist(filename,'file') 
  locked = 0;
  return;
end

if strcmp(computer,'MACI64')
  lockFileCommand = ['lockfile -4 -r 45 ' lockname];
elseif strcmp(computer,'GLNXA64') || strcmp(computer,'GLNX86')
  % for the dream cluster, use lockfile-create
  lockFileCommand = ['lockfile-create --retry 45 ' filename];
end

% see if we can lock it
if system(lockFileCommand)
  % is already locked
  locked = 0;
  return;
end


if strcmp(computer,'MACI64')
  % % we have now locked it, so touch the real file
  system(['touch ' filename ' ; sync']);
elseif strcmp(computer,'GLNXA64') || strcmp(computer,'GLNX86')
  % touch the lockfile
  system(['lockfile-touch --oneshot ' filename ]);
  % % we have now locked it, so touch the real file
  system(['touch ' filename ' ; sync']);
end

locked = 1;
