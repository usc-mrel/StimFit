addpath(genpath('./'))
%   Load MRI data and predefined options structure
load('SampleData/InVivo_4p7T.mat');


%%% FIT SINGLE VOXEL %%%
% S = squeeze(img(171,47,1,:));
% opt.debug = 1;
% opt.Dz = [-0.7 0.7];
% opt.Nz = 45;
% opt.FitType = 'nnls';
% [T2,B1,amp] = StimFitNNLS(S,opt);


%%% FIT ENTIRE IMAGE %%%
opt.debug = 0;
opt.Dz = [-0.7 0.7];
opt.Nz = 45;
opt.th = 0;
opt.FitType = 'nnls';
[T2,B1,amp] = StimFitImgNNLS(img,opt);
