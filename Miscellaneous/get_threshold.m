function th = get_threshold(img,th)
%   Graphical interface to select threshold
%   
%   Author: R. Marc Lebel
%   Date:   06/2011
%   
%   Usage:
%   th = get_threshold(img,th)
%   
%   Input:
%   img: Img to be fit (size: NP x NV x NS x NE)
%   th:  Initial threshold (optional)
%   
%   Output:
%   th:  Selected threshold

%   Check inputs
if nargin < 1
    error('Function requires at least one input');
end

%   Shift and scale img
%   Push into range of [1 256]
if ~isreal(img)
    img = abs(img);
end
mx = max(img(:));
mn = min(img(:));
MX = 256;
img = fscale(img);

%   Get image limits and size
[np nv ns ne] = size(img);

%   Define inital threshold
if nargin < 2 || isempty(th)
    th = 40;
else
    th = fscale(th);
end


%   Create figure
figure(42575);
set(42575,'Name','Select Threshold','NumberTitle','off','Position',...
    [50,100,512,542],'Color','w','DockControls','off','MenuBar','none',...
    'Toolbar','none','Resize','off');

%   Create threshold slider bar
immax  = uicontrol('Style','slider','Position',[0 517 512 20],'Visible',....
    'on','Min',log(1),'Max',log(1000),'Value',log(th),'SliderStep',[0.002 0.1],'Callback',{@th_cb});

%   Create text
%txt = uicontrol('Style','text','String','Select Threshold','Position',[522 445 40 20],'FontSize',14,'BackgroundColor','w','HorizontalAlignment','left');


%   Create plotting axes
ax = axes('Units','pixels','Position',[0 0 512 512],'XTick',[],'YTick',[]);

viewimg;

%   Wait until figure is closed
waitfor(42575);

%   Rescale image
th = iscale(th);



%   Callback and additional functions (inline)
function th_cb(source,~)
    
    %   Update threshold value
    th = exp(get(source,'Value'));
    
    %   Update text and slider
    set(immax,'Value',log(th));
    
    %   Replot appropriate slice
    viewimg;
end

function viewimg
    
    %   Create mask
    mask = img > th;
    mask = 255*double(all(mask,4));
    mask = reshape(mask,[np nv 1 ns]);
    
    %   Plot image
    set(42575,'CurrentAxes',ax);
    montage(mask);
    drawnow;
    
end

function img = fscale(img)
    img = (MX-1) * (img - mn)/(mx-mn) + 1;
end

function img = iscale(img)
    img = (img-1) * (mx-mn)/(MX-1) + mn;
end

end
