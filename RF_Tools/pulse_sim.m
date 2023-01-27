function M = pulse_sim(Mo,z,RF,Gbg)
%   Bloch simulator for RF pulses
%   
%   Author: R. Marc Lebel 01/2010
%   
%   USAGE:
%   M = pulse_sim(Mo,z,RF,Gbg);
%   
%   Input:
%   Mo = initial magnetization array [Mx;My;Mz] (size: 3 x N)
%   z = slice select position axis (cm) (size: 1 x N)
%   RF = RF waveform stucture:
%       .path: path to external waveform file
%       .RF: RF waveform (G)
%       .phase: global phase (degrees)
%       .tau: pulse duration (s)
%       .G: slice-select gradient (G/cm)
%       .ref: refocusing fraction (x2, i.e. near unity for excite; zero for refocus)
%       .angle: prescribed nutation angle (degrees) 
%       .alpha: spatial distribution of nutation angles (degrees)
%   Gbg = background field gradient (G/cm)
%   
%   Output:
%   M = final magnetization vector

%   Check inputs
if nargin < 4
    Gbg = 0;
end

%   Define physical parameters
gamma = 2*pi * 42.575e6 / 10000;

%   Define computational variables
Nt = length(RF.RF);
Nz = length(z);
phi = gamma * (RF.G + Gbg) * z * RF.tau/Nt; %   Dephasing during hard pulse due to gradient
cphi = cos(phi);sphi = sin(phi);
cpRF = cos(RF.phase*pi/180);            %   Global RF phase
spRF = sin(RF.phase*pi/180);
thetaRF = gamma * RF.RF * RF.tau;       %   Incremental tip angle
ctRF = cos(thetaRF);stRF = sin(thetaRF);

%   Loop through pulse steps
% M = Mo;
% for i = 1:Nt
%     
%     %   Apply precession
%     for j = 1:Nz
%         Rz = [cphi(j) sphi(j) 0;-sphi(j) cphi(j) 0;0 0 1];
%         M(:,j) = Rz * M(:,j);
%     end
%     
%     %   Apply incremental tip
%     R = [1 0 0;0 ctRF(i) stRF(i);0 -stRF(i) ctRF(i)];
%     if RF.phase ~= 0
%         Rz = [cpRF spRF 0;-spRF cpRF 0;0 0 1];
%         Rzm = [cpRF -spRF 0;spRF cpRF 0;0 0 1];
%         R = Rzm*R*Rz;
%     end
%     M = R*M;
% %     plot(z,M);
% %     xlabel('Position');ylabel('Magnetization');
% %     legend('Mx','My','Mz');pause(0.05);
% end

%   (Much) faster version of the above
M = pulse_simMEX(Mo,cphi,sphi,ctRF,stRF,cpRF,spRF);

%   Rephase magnetization
if RF.ref > 0
    psi = -RF.ref/2 * gamma * RF.G * z * RF.tau;
    for j = 1:Nz
        Rz = [cos(psi(j)) sin(psi(j)) 0;-sin(psi(j)) cos(psi(j)) 0;0 0 1];
        M(:,j) = Rz * M(:,j);
    end
end


%   Plot (comment if not needed)
% plot(z,M);
% xlabel('Position');ylabel('Magnetization');
% legend('Mx','My','Mz');

