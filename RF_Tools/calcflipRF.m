function RF = calcflipRF(RF,z,Gbg)
%   Computes the tip angles from the RF pulse across the slice profile
%   
%   Usage: RF = calcflipRF(RF,z,Gbg)
%   Author: RM Lebel
%   Date: 06/2011
%   
%   Input:
%   RF = RF waveform stucture:
%       .path: path to external waveform file
%       .RF: RF waveform (G)
%       .phase: global phase (degrees)
%       .tau: pulse duration (s)
%       .G: slice-select gradient (G/cm)
%       .ref: refocusing fraction (x2, i.e. near unity for excite; zero for refocus)
%       .angle: prescribed nutation angle (degrees)
%       .alpha: spatial distribution of nutation angles (degrees) (EMPTY)
%   z = vector of slice positions (cm)
%   Gbg = Background field gradient (G/cm) 
%   
%   Output:
%   RF = RF waveform stucture:
%       .path: path to external waveform file
%       .RF: RF waveform (G)
%       .phase: global phase (degrees)
%       .tau: pulse duration (s)
%       .G: slice-select gradient (G/cm)
%       .ref: refocusing fraction (x2, i.e. near unity for excite; zero for refocus)
%       .angle: prescribed nutation angle (degrees)
%       .alpha: spatial distribution of nutation angles (degrees) (POPULATED)

%   Check input arguments
if nargin ~= 3
    error('Function requires three inputs');
end

%   Define initial magnetization
M = zeros(3,length(z));
M(3,:) = 1;

%   Force small tip angle regime
%   This is one of the major approximations of this method
RF.RF = 1e-4*RF.RF;

%   Perform Bloch simulation
M = pulse_sim(M,z,RF,Gbg);

%   Return from small tip angle regime
RF.RF = 1e4*RF.RF;

%   Compute tip angle
RF.alpha = 1e4 * acos(M(3,:));
