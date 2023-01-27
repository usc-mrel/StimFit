function opt = StimFit_optset(mode)
%   Set options for T2 fit with stimulated echo compensation
%   
%   Author: RML
%   Date: 07/2011
%   
%   Usage: opt = StimFit_optset(mode)
%   
%   Input:
%   mode: acquisition mode. Either:
%       's' for selective refocusing 
%       'n' for non-selective refocusing, either 2D or 3D
%   
%   Output:
%   opt: options structure


%   Check input
if nargin < 1 || (~strcmp(mode,'s') && ~strcmp(mode,'n'))
    disp('Assuming non-selective refocusing');
    opt.mode = 'n';
else
    opt.mode = mode;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   General options for stimulated echo compensated T2 fitting    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Debug flag
opt.debug = 1;          %   Plotting flag: 0 for none; 1 for one voxel only; 2 for all voxels
                        %   use this to verify the simulation options, specifically the spatial width (opt.Dz)
                        %   and number of sample points (opt.Nz) for the RF profile


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   General simulation and sequence options   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt.esp = 10e-3;            %   Inter-echo spacing (s)
opt.etl = 20;               %   Echo train length
if strcmpi(opt.mode,'s')
    opt.Dz  = [-0.5 0.5];   %   Spatial bounds (cm) (should exceed slice thickness, can start at 0 for half profile)
    opt.Nz  = 51;           %   Number of positions to simulate across slice
    opt.Nrf = 64;           %   Number of resampled points in the RF waveform
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Excitation pulse options   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt.RFe.angle = 90;         %   Prescribed excitation pulse angle (degrees)
if strcmpi(opt.mode,'s')
    opt.RFe.path = '';      %   Path to excitation waveform (empty for GUI)
    opt.RFe.RF = [];        %   Placeholder for RF waveform
    opt.RFe.tau = 2.000e-3; %   Duration of excitation pulse (s)
    opt.RFe.G = 0.5000;     %   Slice select gradient during excitation (G/cm)
    opt.RFe.phase = 0;      %   Relative phase (0 in CPMG) (degrees)
    opt.RFe.ref = 1.00;     %   Refocusing fraction (x2, i.e. near unity for excite; zero for refocus)
    opt.RFe.alpha = [];     %   Actual tip angle distribution (degrees) (computed later...)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Refocusing pulse options   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt.RFr.angle = 180;        %   Prescribed refocusing pulse angle (degrees)
if strcmpi(opt.mode,'s')
    opt.RFr.path = '';      %   Path to refocusing waveform (empty for GUI)
    opt.RFr.RF = [];        %   Placeholder for RF wavform
    opt.RFr.tau = 2.000e-3; %   Duration of excitation pulse (s)
    opt.RFr.G = 0.5000;     %   Slice select gradient during excitation (G/cm)
    opt.RFr.phase = 90;     %   Relative phase (90 in CPMG) (degrees)
    opt.RFr.ref = 0.00;     %   Refocusing fraction (x2, i.e. near unity for excite; zero for refocus)
    opt.RFr.alpha = [];     %   Actual tip angle distribution (degrees) (computed later...)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   T1 value; must be provided as a function of T2   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt.T1  = @(T2)3.0;     %   T1 value (s)
% opt.T1  = @(T2)(0.5*T2+1.5);


%%%%%%%%%%%%%%%%%%%%
%   Fitting type   %
%%%%%%%%%%%%%%%%%%%%
opt.FitType = 'lsq';    %   Fit type: 'lsq' for mono- or multi-component non-linear least squares
                        %             'nnls' for non-negative least squares for a pseudo-continuous T2 distribution
opt.th = 0;             %   Noise threshold for image masking (thresh = opt.th*std(noise)). Set to 0 for GUI.
opt.th_te = 1:2;        %   Echo times that must satisfy the thresholding


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Fit options for non-linear least squares    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt.lsq.Ncomp = 1;      %   Number of components to fit: 1, 2, or 3

%   Define boundaries for various tissue compartments and fit models
opt.lsq.Icomp.X0   = [0.060 1e-1 0.99];      %   Starting point (1 x 3) [T2(s) amp(au) B1(fractional)]
opt.lsq.Icomp.XU   = [3.000 1e+3 1.00];      %   Upper bound (1 x 3)
opt.lsq.Icomp.XL   = [0.015 0.00 0.30];      %   Lower bound (1 x 3)
opt.lsq.IIcomp.X0  = [0.020 1e-1 0.131 1e-1 0.99];    %   Starting point (1 x 5) [T2(s) amp(au) T2(s) amp(au) B1(fractional)]
opt.lsq.IIcomp.XU  = [0.250 1e+3 3.000 1e+3 1.20];    %   Upper bound (1 x 5)
opt.lsq.IIcomp.XL  = [0.015 0.00 0.250 0.00 0.30];    %   Lower bound (1 x 5)
opt.lsq.IIIcomp.X0 = [0.020 1e-1 0.036 1e-1 0.131 1e-1 0.80];  %   Starting point (1 x 5) [T2(s) amp(au) T2(s) amp(au) T2(s) amp(au) B1(fractional)]
opt.lsq.IIIcomp.XU = [0.035 1e+3 0.130 1e+3 3.000 1e+3 1.20];  %   Upper bound (1 x 7)
opt.lsq.IIIcomp.XL = [0.015 0.00 0.035 0.00 0.130 0.00 0.30];  %   Lower bound (1 x 7)

%   Numeric fitting options
opt.lsq.fopt = optimset('lsqnonlin');
opt.lsq.fopt.TolX = 5e-4;     %   Fitting accuracy: 0.5 ms
opt.lsq.fopt.TolFun = 1.0e-9;
opt.lsq.fopt.MaxIter = 100;
opt.lsq.fopt.Display = 'off';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Fit options for non-negative least squares    %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
opt.nnls.lambda = 1.02;         %   Desired misfit (regularization factor)
opt.nnls.T2range = [0.01 3];    %   Range of T2 values to model (s) [min max]
opt.nnls.NT2 = 120;             %   Number of T2 values to model
if strcmpi(opt.mode,'s') 
    opt.nnls.B1range = [0.3 1.2];   %   Range of B1 values (fractional B1+ field). Unstable above unity, but can work with high SNR data.
else
    opt.nnls.B1range = [0.3 1.0];   %   Cannot exceed unity unless selective pulses are used.
end
opt.nnls.NB1 = 250;             %   Number of B1 values to model
opt.nnls.A = [];                %   The solution space (size: ETL x NT2 x NB1), computed in StimFitNNLS.m
opt.nnls.Ahash = [];            %   Ensures A is consistent with opt.nnls paramters, computed in StimFitNNLS.m

