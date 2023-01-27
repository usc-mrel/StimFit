function [RF,RFinterp,fname] = readRF(fname,N,str)
%   Reads a waveform file
%   
%   Author: RML
%   Date: 06/2011
%   
%   Usage: [RF,RFinter,fname] = readRF(fname,N,str)
%   
%   Input:
%   fname: RF waveform path and file name
%   N: number of points in resampled waveform
%   str: string for GUI
%   
%   Output:
%   RF: complex RF waveform, arbitrary scaling
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
    ffilt = {'*.RF' 'Varian RF file';'*.pta' 'Siemens RF file';'*.rho' 'GE RF file'};
    [fname,pathname] = uigetfile(ffilt,str,'./','MultiSelect','off');
else
    [pathname,fname,ext] = fileparts(fname);
    fname = [fname ext];
end

%   Combine for full path and file name and get extension
fname = fullfile(pathname,fname);
[~,~,ext] = fileparts(fname);

%   Call appropriate parsing function
switch ext
    case '.RF'
        [RF,RFinterp,fname] = readRF_Varian(fname,N,str);
        
    case '.pta'
        [RF,RFinterp,fname] = readRF_Siemens(fname,N,str);
        
    case '.rho'
        
    otherwise
        error('RF type not supported');
end
