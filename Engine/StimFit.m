function [T2, B1, amp, opt] = StimFit(S,opt)
%   T2 fitting routine with stimulated echo compensation
%   
%   Author: R. Marc Lebel
%   Date:   06/2011
%   
%   Usage:
%   [T2 B1 amp opt] = StimFit(S,opt)
%   
%   Input:
%   S:   Signal vector to be fit (1 x ETL)
%   opt: Options structure defined by StimFit_optset (optional)
%   
%   Output:
%   T2:  Decay time (s)
%   B1:  Relative transmit field (au, near unity)
%   amp: Relative amplitude (au)
%   opt: Modified options structure


%   Check inputs
if nargin < 1
    error('Function requires at least one input');
end
if nargin < 2 || isempty(opt) || ~isstruct(opt)
    opt = StimFit_optset;
end

%   Check options to determine type of fitting
if strcmp(opt.FitType,'nnls')
    warning('StimFit:FitType','Switching to non-negative least squares fit');
    [T2, B1, amp, opt] = StimFitNNLS(S,opt);
    return
end

%   Check to ensure echo train lengths match
if length(S) ~= opt.etl
    error('Inconsistent echo train length');
end

%   Read RF waveform and compute the tip angle distribution
%   Check if RF pulse information is needed
if strcmpi(opt.mode(1),'s')
    opt.RFe = getRF(opt.RFe,opt.Nrf,opt.Dz,opt.Nz,'Select RF waveform (excitation)');
    opt.RFr = getRF(opt.RFr,opt.Nrf,opt.Dz,opt.Nz,'Select RF waveform (refocusing)');
end

%   Perform bounded non-linear least squares fitting
switch opt.lsq.Ncomp
    case 1
        [X,~,~,~,info] = lsqnonlin(@diff_sig,opt.lsq.Icomp.X0,...
            opt.lsq.Icomp.XL,opt.lsq.Icomp.XU,opt.lsq.fopt);
        T2 = X(1); amp = X(2); B1 = X(3);
        
    case 2
        [X,~,~,~,info] = lsqnonlin(@diff_sig,opt.lsq.IIcomp.X0,...
            opt.lsq.IIcomp.XL,opt.lsq.IIcomp.XU,opt.lsq.fopt);
        T2 = X([1 3]); amp = X([2 4]); B1 = X(5);
        
    case 3
        [X,~,~,~,info] = lsqnonlin(@diff_sig,opt.lsq.IIIcomp.X0,...
            opt.lsq.IIIcomp.XL,opt.lsq.IIIcomp.XU,opt.lsq.fopt);
        T2 = X([1 3 5]); amp = X([2 4 6]); B1 = X(7);
end
if opt.debug
    fprintf('Fitting info:\n\tIterations: %g\n\tFunction Count:%g\n',...
        info.iterations,info.funcCount);
    fprintf('Fitting info: %s\n',info.message);
end


%   Objecitve function for least squares fitting
function delta = diff_sig(X)
    
    %   Compute candidate signal via EPG algorithm
    switch opt.lsq.Ncomp
        case 1
            Sfit = X(2).*FSEsig(X(1),X(3),0,opt);
            
        case 2
            Sfit = X(4).*FSEsig(X(3),X(5),0,opt) + X(2).*FSEsig(X(1),X(5),0,opt);
            
        case 3
            Sfit = X(2).*FSEsig(X(1),X(7),0,opt) + X(6).*FSEsig(X(5),X(7),0,opt) + ...
                   X(4).*FSEsig(X(3),X(7),0,opt);
    end
    
    %   Compute objective function (signal difference)
    delta = S(:) - Sfit(:);
    
    
    %   Plot signal
    if opt.debug
        te = opt.esp:opt.esp:opt.esp*opt.etl;
        figure(42575);
        
        switch lower(opt.mode)
            case 'n'
                subplot(1,2,1);
            case 's'
                subplot(2,4,4);
        end
        plot(te,S,'o',te,Sfit);
        switch opt.lsq.Ncomp
            case 1
                title(sprintf('T2 = %08.3f ms  A = %04.2f  B1 = %05.3f',...
                    X(1)*1e3,X(2),X(3)));
            case 2
                title(sprintf(['B1 = %05.3f\nT2 = %08.3f ms  A = %05.2f\n',...
                    'T2 = %08.3f ms  A = %05.2f'],...
                    X(5),X(1)*1e3,X(2),X(3)*1e3,X(4)));
            case 3
                title(sprintf(['B1 = %05.3f\nT2 = %08.3f ms  A = %05.2f\n',...
                    'T2 = %08.3f ms  A = %05.2f\n',...
                    'T2 = %08.3f ms  A = %05.2f'],...
                    X(7),X(1)*1e3,X(2),X(3)*1e3,X(4),X(5)*1e3,X(6)));
        end
        set(gca,'XLim',[0 te(end)+opt.esp/2],'YLim',[0 Inf],'LineWidth',1);grid on;
        xlabel('Echo time (s)');ylabel('Mt (au)');
        
        switch lower(opt.mode)
            case 'n'
                subplot(1,2,2);
            case 's'
                subplot(2,4,8);
        end
        resid = 100/S(1)*delta;
        plot(te,resid);
        set(gca,'XLim',[0 te(end)+opt.esp/2],'LineWidth',1);grid on;
        xlabel('Echo time (s)');ylabel('Residual (%)');
        title(sprintf('Residuals (MSE = %07.4f)',sum(delta.^2)));
        drawnow;
    end
end


end
