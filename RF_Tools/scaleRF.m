function RF = scaleRF(RF,tau,angle)
%   Scales an RF waveform to produce a desired tip angle
%   
%   Author: RML
%   Date: 06/2011
%   
%   Usage: RF = scaleRF(RF,tau,angle)
%            ----OR----
%          RF = scaleRF(RF)
%   
%   Input (case 1):
%   RF: RF waveform (arbitrary scaling)
%   tau: pulse duration (s)
%   angle: desired flip angle (degrees)
%   
%   Input (case 2):
%   RF = RF waveform stucture:
%       .path: path to external waveform file
%       .RF: RF waveform (arbitrary scaling)
%       .phase: global phase (degrees)
%       .tau: pulse duration (s)
%       .G: slice-select gradient (G/cm)
%       .ref: refocusing fraction (x2, i.e. near unity for excite; zero for refocus)
%       .angle: prescribed nutation angle (degrees) 
%       .alpha: spatial distribution of nutation angles (degrees)
%   
%   
%   Output (case 1):
%   RF: complex RF waveform (G)
%   
%   Output (case 2):
%   RF = RF waveform stucture:
%       .path: path to external waveform file
%       .RF: RF waveform (G)
%       .phase: global phase (degrees)
%       .tau: pulse duration (s)
%       .G: slice-select gradient (G/cm)
%       .ref: refocusing fraction (x2, i.e. near unity for excite; zero for refocus)
%       .angle: prescribed nutation angle (degrees) 
%       .alpha: spatial distribution of nutation angles (degrees)

%   Define some parameters
gamma = 2*pi*42.575e6;  %   Hz/T

if ~isstruct(RF)
    %   Get current angle
    alphaC = gamma*tau*abs(sum(RF(:)));
    alphaC = alphaC * 180/pi;   %   Degrees
    
    %   Compute scaling factor
    SF = angle./alphaC;
    
    %   Scale the RF waveform
    RF = SF*RF*10000;  %   Gauss
    
elseif isstruct(RF)
    %   Get current angle
    alphaC = gamma*RF.tau*abs(sum(RF.RF(:)));
    alphaC = alphaC * 180/pi;   %   Degrees
    
    %   Compute scaling factor
    SF = RF.angle ./ alphaC;
    
    %   Scale the RF waveform
    RF.RF = SF*RF.RF*10000;     %   Gauss
end
