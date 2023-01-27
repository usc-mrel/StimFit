function [S,err] = bloch_sim(T1,T2,B1,esp,etl,z,Gcr,RFe,RFr)
%   Bloch simulator for crushed multi spin echo
%   
%   Usage: [S, err] = bloch_sim(T1,T2,B1,esp,etl,z,Gcr,RFe,RFr)
%   Author: RM Lebel
%   Date: 06/2011
%   
%   Input:
%   T1: T1 relaxation time (s)
%   T2: T2 relaxation time (s)
%   B1: scale factor for transmit
%   esp: echo spacing (s)
%   etl: echo train length
%   z: vector of slice positions (cm)
%   Gcr: crusher gradient amplitude (G/cm)
%   RFe: structure defining excitation pulse
%       .RF: RF waveform (G)
%       .phase: global phase (degrees)
%       .tau: pulse duration (s)
%       .G: slice-select gradient (G/cm)
%       .ref: refocusing factor (near unity)
%   RFr: structure defining refocusing pulse
%       .RF: RF waveform (G)
%       .phase: global phase (degrees)
%       .tau: pulse duration (s)
%       .G: slice-select gradient (G/cm)
%       .ref: refocusing factor (usually zero)
%   
%   Output:
%   S: echo amplitudes (au)
%   err: fractional x component of the echo amplitude
%       This component should not exist. Monitor for crushing errors

%   Start timer
tic;

pl = 0;

%   Define variables and constants
gamma = 2*pi * 42.575e6 / 10000;
Nz = length(z);
M = [zeros(1,Nz);zeros(1,Nz);ones(1,Nz)];
phi = gamma * Gcr * z * esp/2;
cphi = cos(phi);sphi = sin(phi);
T = [exp(-esp/(2*T2)) 0 0;0 exp(-esp/(2*T2)) 0;0 0 exp(-esp/(2*T1))];
S = zeros(1,etl);
Sx = zeros(1,etl);

%   Scale RF pulses
RFe.RF = B1 .* RFe.RF;
RFr.RF = B1 .* RFr.RF;

%   Apply excitation pulse
M = pulse_sim(M,z,RFe);drawnow
if pl
    figure(1);plot(z,M(1,:),z,M(2,:),z,M(3,:));drawnow;
end

%   Loop through echoes
for i = 1:etl
    
    %   Apply precession and relaxation pre-refocusing
    for j = 1:Nz
        Rz = [cphi(j) sphi(j) 0;-sphi(j) cphi(j) 0;0 0 1];
        M(:,j) = T*Rz * M(:,j);
    end
    
    if pl
        figure(2);plot(z,M(1,:),z,M(2,:),z,M(3,:));pause(0.25);
    end
    
    %   Apply refocusing pulse
    M = pulse_sim(M,z,RFr);
    
    %   Apply precession and relaxation post-refocusing
    for j = 1:Nz
        Rz = [cphi(j) sphi(j) 0;-sphi(j) cphi(j) 0;0 0 1];
        M(:,j) = T*Rz * M(:,j);
    end
    
    %   Save echo amplitude (only y component in CPMG)
    S(i) = sum(M(2,:));
    
    %   Save x component (a measure of disretization error)
    Sx(i) = sum(M(1,:));
    
    if pl
        figure(2);plot(z,M(1,:),z,M(2,:),z,M(3,:));pause(0.25);
    end
    
end

%   Normalize the signal
err = Sx./S;
S = S./S(1);
if pl
    figure(3);plot(1:etl,S,1:etl,err);
end
% S = S.*mean(diff(z));

%   Stop timer
t = toc;
fprintf('Computation time: %g s\n',round(100*t)/100);

