function RF = getRF(RF,Nrf,dz,Nz,str)
%   Populates RF waveform structure with crucial data
%   
%   Usage: RF = getRF(RF,Nrf,dz,Nz,str)
%               -----OR-----
%          opt = getRF(opt);
%
%   Author: R. Marc Lebel
%   Date: 06/2011
%   
%   Input:
%   RF = RF waveform stucture:
%       .path: path to external waveform file
%       .RF: RF waveform (G) (EMPTY)
%       .phase: global phase (degrees)
%       .tau: pulse duration (s)
%       .G: slice-select gradient (G/cm)
%       .ref: refocusing fraction (x2, i.e. near unity for excite; zero for refocus)
%       .angle: prescribed nutation angle (degrees) 
%       .alpha: spatial distribution of nutation angles (degrees) (EMPTY)
%   Nrf= Number of points in final waveform
%   dz = Width of slice (cm)
%   Nz = Number of points in slice
%   str= string to display on dialogue box
%
%           -----OR-----
%   
%   opt = options structure as defined by StimFit_optset.m
%   
%   
%   Output:
%   RF = RF waveform stucture:
%       .path: path to external waveform file
%       .RF: RF waveform (G) (POPULATED)
%       .phase: global phase (degrees)
%       .tau: pulse duration (s)
%       .G: slice-select gradient (G/cm)
%       .ref: refocusing fraction (x2, i.e. near unity for excite; zero for refocus)
%       .angle: prescribed nutation angle (degrees)
%       .alpha: spatial distribution of nutation angles (degrees) (POPULATED)
%   
%           -----OR-----
%   
%   opt = options structure with RF sub-structures populated as above
%   

%   Check inputs
if nargin < 1
    error('Function requires at least one input');
end

%   If a single RF structure is given
if isfield(RF,'G') && isfield(RF,'ref')
    
    if nargin < 4
        error('This usage requires at least 4 inputs');
    end
    if nargin < 5
        str = 'Select RF waveform';
    end
    
    %   Check for RF waveforms in the options structure
    %   If needed, read external waveform and scale to desired tip
    if isempty(RF.RF) || length(RF.RF) ~= Nrf
        [~,RF.RF,RF.path] = readRF(RF.path,Nrf,str);
    end
    RF = scaleRF(RF);
    
    %   Compute the spatial distribution of pulse angles
    z = dz(1):(dz(2)-dz(1))/(Nz-1):dz(2);
    RF = calcflipRF(RF,z,0);
    
%   If entire options strucuture is passed
else
    
    %   Get field names of entire input structure (as set by StimFit_optset.m)
    fnames = fieldnames(RF);
    
    %   Loop through fields
    for i = 1:length(fnames)
        
        %   Test if current field is an RF structure (just look from some
        %   defining field names, like G and ref)
        fld = RF.(char(fnames(i)));
        if isstruct(fld) && isfield(fld,'G') && isfield(fld,'ref')
            
            %   Check for RF waveforms in the options structure
            %   If needed, read external waveform and scale to desired tip
            if isempty(fld.RF)
                [~,fld.RF,fld.path] = readRF(fld.path,RF.Nrf,'Select RF waveform');
                fld = scaleRF(fld);
            end
            
            %   Compute the spatial distribution of pulse angles
            z = RF.Dz(1):(RF.Dz(2)-RF.Dz(1))/(RF.Nz-1):RF.Dz(2);
            fld = calcflipRF(fld,z,0);
            
            %   Update the global structure with new values
            RF.(char(fnames(i))) = fld;
        end
        
    end
end
    

end
