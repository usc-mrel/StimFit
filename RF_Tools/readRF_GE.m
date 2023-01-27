function [RF,RFinterp,fname] = readRF_GE(fname,N,str)
%   Reads a .RF file
%   
%   Author: RML
%   Date: 04/2012
%   
%   Usage: [RF,RFinter,fname] = readRF_GE(fname,N,str)
%   
%   Input:
%   fname: RF waveform path and file name
%   N: number of points in resampled waveform
%   str: string for GUI
%   
%   Output:
%   RF: RF waveform, arbitrary scaling
%   RFinterp: interpolated waveform, arbitrary scaling
%   fname: path and file name

%   Check input
if nargin < 3
    str = 'Select RF file';
end
if nargin < 2
    N = 32;
end
if nargin < 1 || isempty(fname)
    [fname,pathname] = uigetfile('*.rho',str,'./','MultiSelect','off');
else
    pathname = pwd;
end

%   Open file
fname = fullfile(pathname,fname);
fid = fopen(fname,'r');
fprintf('Reading RF file: %s\n',fname);

%   Read file
RF = fread(fid,inf,'int16',0,'b');
RF = RF(33:end-2);  % Strips 5x header

%   Close file
fclose(fid);

%   Resample RF waveform
if nargout > 1
    t1 = 0:length(RF)-1;
    t2 = 0:(length(RF)-1)/(N-1):length(RF)-1;
    RFinterp = interp1(t1,RF,t2,'linear');
end
