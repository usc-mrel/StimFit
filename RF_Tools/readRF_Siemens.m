function [RF,RFinterp,fname] = readRF_Siemens(fname,N,str)
%   Reads a .RF file
%   
%   Author: RML
%   Date: 06/2011
%   
%   Usage: [RF,RFinter,fname] = readRF_Siemens(fname,N,str)
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
    [fname,pathname] = uigetfile('*.pta',str,'./','MultiSelect','off');
else
    pathname = pwd;
end

%   Open file
fid = fopen(fname,'r');
fname = fullfile(pathname,fname);
fprintf('Reading RF file: %s\n',fname);

%   Read file
RF = [];
while ~feof(fid)
    line = fgetl(fid);
    if ~isletter(line(1)) && ~isspace(line(1))
        vals = sscanf(line,'%f');
        if abs(vals(2)-pi) < 0.001
            rf = -vals(1);
        elseif abs(vals(2)) < 0.001
            rf = vals(1);
        else
            rf = vals(1).*exp(sqrt(-1)*vals(2));
        end
        RF = [RF; rf]; %#ok<AGROW>
    end
end
RF = RF.';

%   Close file
fclose(fid);

%   Issue warning if complex
if ~isreal(RF)
    warning('readRF_Siemens:ComplexWaveform','Complex RF waveforms not yet supported');
    RF = real(RF);
end

%   Resample RF waveform
if nargout > 1
    t1 = 0:length(RF)-1;
    t2 = 0:(length(RF)-1)/(N-1):length(RF)-1;
    RFinterp = interp1(t1,RF,t2,'linear');
end
