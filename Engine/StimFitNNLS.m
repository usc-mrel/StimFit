function [T2, B1, amp, opt] = StimFitNNLS(S,opt)
%   T2 fitting routine with stimulated echo compensation
%   
%   Author: R. Marc Lebel
%   Date:   07/2011
%   
%   Usage:
%   [T2 B1 amp opt] = StimFitNNLS(S,opt)
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
if strcmp(opt.FitType,'lsq')
    warning('StimFitNNLS:FitType','Switching to non-linear least squares fit');
    [T2, B1, amp, opt] = StimFit(S,opt);
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

%   Define T2 and B1 vectors. T2 is logarithmically spaced; B1 is linear
T2 = logspace(log10(opt.nnls.T2range(1)),log10(opt.nnls.T2range(2)),opt.nnls.NT2);
B1 = linspace(opt.nnls.B1range(1),opt.nnls.B1range(2),opt.nnls.NB1);

%   Compute the signal decay matrix at multiple T2 and B1, if needed
if isempty(opt.nnls.A) || (isempty(opt.nnls.Ahash) || opt.nnls.Ahash ~= comp_A_hash(opt))
    comp_A;
end

%   Determine relative B1+ and minimum sum squared error
optmp = optimset('fminbnd');
optmp.TolX = 0.25;
[ind,SSE] = fminbnd(@NNLSB1_obj,0.5,opt.nnls.NB1+0.5-eps,optmp);
ind = round(ind);
B1 = B1(ind);
A = opt.nnls.A(:,:,ind);

%   Search for regularization parameter that gives the desired mis-fit
optmp = optimset('fminbnd');
optmp.TolX = 2e-4;
reg = eye(opt.nnls.NT2 + 1);
mu = fminbnd(@NNLSreg_obj,0,1,optmp);

%   Perform regularized fit with known B1 and optimal regularization
amp = lsqnonneg([A;mu*reg],[S;zeros(opt.nnls.NT2+1,1)]);

%   Plot
plot_nnls


%   Subfunction to compute the possible decay at all T2 and B1
function comp_A
    
    %   Initialize A [size: ETL x nT2 x nB1]
    opt.nnls.A = zeros(opt.etl,opt.nnls.NT2 + 1,opt.nnls.NB1);
    
    %   Compute decay at every possible T2 and B1
    dbg = opt.debug;
    if dbg
        fprintf('Precomputing the signal matrix...\n');
    end
    for iB1 = opt.nnls.NB1:-1:1
        for iT2 = 1:opt.nnls.NT2
            opt.nnls.A(:,iT2,iB1) = FSEsig(T2(iT2),B1(iB1),0,opt);            
        end
        opt.nnls.A(:,iT2+1,iB1) = 1;    %   Adds DC offset
        opt.debug = 0;drawnow;
        if dbg && ~mod(iB1,10)
            fprintf('  %5.1f%%\n',(opt.nnls.NB1-iB1)/opt.nnls.NB1*100);
        end
    end
    if dbg
        fprintf('...done\n');
    end
    opt.debug = dbg;
    
    %   Compute hash value for this signal matrix
    opt.nnls.Ahash = comp_A_hash(opt);
    
end


%   Function to compute a "hash" value to ensure the precomputed signal
%   matrix matches the requested parameters. This avoids the need to
%   recompute if the same parameters are used
function h = comp_A_hash(opt)
    h = opt.etl^0.1 * opt.nnls.NT2^0.2 * opt.nnls.NB1^0.3 * ...
        opt.nnls.T2range(1)^0.05 * opt.nnls.T2range(2)^0.1 * ...
        diff(opt.nnls.T2range) * opt.nnls.B1range(1)^0.05 * ...
        opt.nnls.B1range(2)^0.1 * diff(opt.nnls.B1range);
end


%   Objective function for B1 estimation
function SSEr = NNLSB1_obj(x)
    [~,SSEr] = lsqnonneg(opt.nnls.A(:,:,round(x)),S);
end


%   Objective function for regularization
function f = NNLSreg_obj(x)
    [~,SSEr] = lsqnonneg([A;x*reg],[S;zeros(opt.nnls.NT2+1,1)]);
    f = abs(SSEr - opt.nnls.lambda*SSE)./SSE;
end


%   Plotting function
function plot_nnls
    if opt.debug
        
        if ~any(findobj == 42575)
            figure(42575);
            scrsz = get(0,'ScreenSize');
            set(42575,'Name','NNLS Fit','NumberTitle','off',...
                'Position',[scrsz(3)/10 scrsz(4)/2 scrsz(3)/1.75 scrsz(4)/2.75],...
                'Resize','off','Toolbar','none','Color','w');
        end
        
        subplot(2,2,[1 2]);
        semilogx(T2,amp(1:end-1));
        set(gca,'XLim',[min(T2) max(T2)],'LineWidth',1);grid on;
        xlabel('T2 (s)');ylabel('Amplitude (au)');title('Relaxation Distribution');
        
        subplot(2,2,3);
        te = opt.esp:opt.esp:opt.esp*opt.etl;
        plot(te,S,'o',te,A*amp);
        set(gca,'XLim',[0 te(end)+opt.esp/2],'YLim',[0 Inf],'LineWidth',1);grid on;
        xlabel('Echo time (s)');ylabel('Mt (au)');
        title(sprintf('Stimulated Echo Compensating Fit  (B1 = %05.3f)',B1));
        
        subplot(2,2,4);
        resid = 100/S(1)*(S - A*amp);
        plot(te,resid);
        set(gca,'XLim',[0 te(end)+opt.esp/2],'LineWidth',1);grid on;
        xlabel('Echo time (s)');ylabel('Residual (%)');
        title(sprintf('Residuals (MSE = %07.4f)',sum((S - A*amp).^2)));
        drawnow;
    end
end

end

