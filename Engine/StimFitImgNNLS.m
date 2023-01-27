function [T2, B1, amp, opt] = StimFitImgNNLS(img,opt)
%   T2 fitting routine with stimulated echo compensation
%   
%   Author: R. Marc Lebel
%   Date:   07/2011
%   
%   Usage:
%   [T2 B1 amp opt] = StimFitImgNNLS(img,opt)
%   
%   Input:
%   img: Img to be fit (size: NP x NV x NS x NE)
%   opt: Options structure defined by StimFit_optset (optional)
%   
%   Output:
%   T2:  Array of decay times (determined by opt) (size: 1 x NT2)
%   B1:  Relative transmit field (au, near unity) (size: NP x NV x NS)
%   amp: Distribution of T2 components (au) (size: NP x NV x NS x NT2)
%   opt: Modified options structure


%   Check input arguments
if nargin < 1
    error('Function requires at least 1 input');
end
if nargin < 2 || isempty(opt) || ~isstruct(opt)
    opt = StimFit_optset;
end

%   Check options to determine type of fitting
if strcmp(opt.FitType,'lsq')
    warning('StimFitImg:FitType','Switching to non-linear least squares fit');
    [T2, B1, amp, opt] = StimFitImg(img,opt);
    return
end

%   Get and store image size, check for consistency
[opt.size(1),opt.size(2),opt.size(3),opt.size(4)] = size(img);
if opt.etl ~= opt.size(4)
    warning('StimFitImg:InconsistentParameters',...
        'opt.etl (=%g) has been modified to match image size (=%g)',opt.etl,opt.size(4));
    opt.etl = opt.size(4);
end


%   Read RF waveform and compute the tip angle distribution
%   Check if RF pulse information is needed
if strcmpi(opt.mode(1),'s')
    disp('Generating RF Waveforms and Computing Slice Profiles');
    opt.RFe = getRF(opt.RFe,opt.Nrf,opt.Dz,opt.Nz,'Select RF waveform (excitation)');
    opt.RFr = getRF(opt.RFr,opt.Nrf,opt.Dz,opt.Nz,'Select RF waveform (refocusing)');
end


%   Check that image is real and double
if ~isreal(img)
    img = abs(img);
    warning('StimFitImg:ComplexImage','Image is complex. Taking absolute value');
end
if isa(img,'single')
    img = double(img);
end

%   Scale image. The fit routine is bounded, so arbitrarily scaled images
%   are not guaranteed to work - we want the signal to be within an order
%   of magnitude (or so) of unity
disp('Scaling Image and Removing Noise Bias');
i1 = img(:,:,:,1);
img = img ./ mean(i1(:));
clear i1

%   Remove noise baseline and define a fitting threshold
%   Estimate noise based on bottom portion of image
%   Threshold is based on noise STD
noise = img(floor(0.95*opt.size(1)):opt.size(1),floor(0.95*opt.size(2)):opt.size(2),:,:);
img = img - mean(noise(:));
if isempty(opt.th) || opt.th == 0
    th = get_threshold(img(:,:,:,opt.th_te),2.5*std(noise(:)));
else
    th = opt.th*std(noise(:));
end
clear noise

%   Compute number of voxels to fit
mask = img(:,:,:,opt.th_te) > th;
mask = all(mask,4);
nTot = sum(mask(:));
if opt.debug && ~(isempty(opt.th) || opt.th == 0)
    montage(reshape(mask,[opt.size(1) opt.size(2) 1 opt.size(3)]));
    title('Mask')
end
clear mask

%   Initialize output variables
B1  = zeros(opt.size(1:3));
amp = zeros([opt.size(1:3) opt.nnls.NT2+1]);

%   Loop through voxels and fit
disp('Performing Stimulated Echo Compensated Fit');
nFit = 0;
t0 = tic;
for npi = 1:opt.size(1) %   Could parallelize this loop
for nvi = 1:opt.size(2)
for nsi = 1:opt.size(3)
    
    %   Check if voxel is above fitting threshold
    %   Use 1st + 2nd time points - the 2nd can be larger than the 1st!
    if all(img(npi,nvi,nsi,opt.th_te) > th)
        
        %   Extract signal and fit
        S = img(npi,nvi,nsi,:);
        [T2 B1(npi,nvi,nsi) amp(npi,nvi,nsi,:) opt] = StimFitNNLS(S(:),opt);
        
        %   Disable debug if needed
        if opt.debug == 1
            opt.debug = 0;
        end
        
        %   Progress counter
        nFit = nFit + 1;
        
        %   Periodically display progress
        if ~mod(nFit,500)
            fprintf('%5.1f%% Complete (~%5.1f minutes remaining)\n',...
                nFit/nTot*100,toc(t0)/nFit * (nTot-nFit)/60);
        end
    end
    
end
end
end

%   Save Data
save('./StimFitNNLS.mat','img','opt','T2','amp','B1');

end

