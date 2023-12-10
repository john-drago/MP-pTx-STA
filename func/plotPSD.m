function [imgParamOptFig] = plotPSD(MP, binVis, cMax)
arguments
    MP
    binVis = true
    cMax = false
end

%% Get Structs
Waveform = MP.Waveform;
Val = MP.Val;
opt = MP.opt;

%% Parameters before the waveform
percHorzReduce = 0.25; % first index is horizontal
percVertReduce = 0.05; % second index is vertical
roundN = 3;
fontSizeMetric = 13;
outlineLineWidth = 1.75;
lineWidth = 2.5;
% fontSizeAx = 16;

phasem = phasemap(256);
magm = colorcet('L09');

%% Determine Which Planes to Use
numImgs = 20;
sliceIdx = sliceIdxNumImgs( numImgs, Val.roi_brain_planes );

%% Pre plot computations

if cMax
    cMagMax = cMax;
else
    cMagMax = round( 7 * sin( opt.FAtarg ), 1) / 4; % round to nearest 0.05
end
cMagAx = [0, cMagMax];

%% Get roiFOV
roiBrainPlanes = Val.roi_brain_planes;
roiBrainPlanes = roiBrainPlanes( :, :, sliceIdx );

%% Determine Which Arrays to Use (Fwd vs. Bloch Sim) for Plotting
Mmpptx_xy3Dplanes = Val.Mmpptx_xy3Dplanes( :, :, sliceIdx);

%% Create the mosaics
CompImg = rearrangeCutImgStack(Mmpptx_xy3Dplanes, percHorzReduce, percVertReduce);
BrainOutline = rearrangeCutImgStack(roiBrainPlanes, percHorzReduce, percVertReduce);

%% Get Values
NRMSE = opt.mpptx_magNRMSE;
FAstd = opt.mpptx_FAStd;
FA = opt.mpptx_FAMean;
GlobalPower = opt.mpptx_PulsePower;

%% Get Waveforms
tvec = Waveform.tvec;
Grad = Waveform.Grad;
Shim = Waveform.Shim;
RFphasor = Waveform.RFphasor;
Freq = Waveform.Freq;
numZCoils = size(Shim , 1);
tend = tvec(end);

%% Define Params to Use During Plotting

ColorMax = 1;
ColorMin = 0.25;
OtherMax = 0.75;

if mod(numZCoils,2) == 0
    numInt = numZCoils/2;
    dcDark = (ColorMax-ColorMin)/(numInt);
    interpDark = (ColorMin:dcDark:ColorMax).';
    shimColorsDark = [...
        zeros(length(interpDark), 1),...
        zeros(length(interpDark), 1) ...
        interpDark,...
        ];

    dcLight = (OtherMax-0)/(numInt-1);
    interpLight = (dcLight:dcLight:OtherMax).';
    shimColorsLight = [...
        interpLight,...
        interpLight,...
        ones(length(interpLight), 1),...
        ];

    shimColors = [ shimColorsDark; shimColorsLight ];
elseif numZCoils == 1
    shimColors = [ 0, 0, 1 ];
else
    numInt = floor(numZCoils/2);
    dcDark = (ColorMax-ColorMin)/numInt;
    interpDark = (ColorMin:dcDark:ColorMax).';
    shimColorsDark = [...
        zeros(length(interpDark), 1),...
        zeros(length(interpDark), 1),...
        interpDark,...
        ];

    dcLight = (OtherMax-0)/numInt;
    interpLight = (dcLight:dcLight:OtherMax).';
    shimColorsLight = [...
        interpLight,...
        interpLight,...
        ones(length(interpLight), 1),...
        ];
    shimColors = [ shimColorsDark; shimColorsLight ];
end

shimColors = flip( shimColors, 1 );
shimColors = num2cell(shimColors, 2);

gradColors = num2cell(lines(4), 2);
gradColors = gradColors(2:end);

%%  Plot the Param Output
if binVis
    imgParamOptFig = figure('color', 'white', 'Units', 'pixels',...
        'Visible','on');
else
    dfws = get(groot, 'defaultfigurewindowstyle');
    set(groot, 'defaultfigurewindowstyle','normal')
    imgParamOptFig = figure('color', 'white', 'Units', 'pixels',...
        'Visible','off','position', [1 1 1650 800]);
end

% PSDTL = tiledlayout( 4, 3,...
%     'padding', 'compact');
tiledlayout( 4, 3,...
    'padding', 'compact');

%% Magnetization Magnitude Plot
magAx = nexttile( 1, [2 1] ); 
hold(magAx, 'on');
imagesc( magAx, fliplr(permute( abs(CompImg) ,[2 1])));
set(magAx, 'ydir', 'normal');
axis(magAx, 'image');
xticklabels([]);
yticklabels([]);
magAx.Title.String = ['\textbf{', 'MP-pTx', '}'];
magAx.Title.Interpreter = 'latex';
caxis(magAx, cMagAx); %#ok
colormap(magAx, magm)
[~, contMagAx] =  imcontour( fliplr(permute( BrainOutline, [2 1] )), 1);
contMagAx.Color = 'w';
contMagAx.LineWidth = outlineLineWidth;
% set(magAx, 'visible', 'off')
pause(0.1)
cbMag = colorbar(magAx);
cbMag.TickLabelInterpreter = 'latex';
cbMag.FontSize = fontSizeMetric-2;
ylabel(cbMag, '$|M_{xy}|$', 'Interpreter','latex', 'fontsize', fontSizeMetric+2)

%% Magnetization Phase Plot
phAx = nexttile( 7, [2 1] );
hold(phAx, 'on');
imagesc( phAx, fliplr(permute( angle(CompImg) ,[2 1])));
set(phAx, 'ydir', 'normal');
axis(phAx, 'image');
xticklabels([]);
yticklabels([]);
caxis(phAx,  [-pi, pi]); %#ok
colormap(phAx, phasem)
[~, contPhAx] =  imcontour( fliplr(permute( BrainOutline, [2 1] )), 1);
contPhAx.Color = 'w';
contPhAx.LineWidth = outlineLineWidth;
set(phAx, 'visible', 'off')
pause(0.1)
cbPh = colorbar(phAx);
cbPh.TickLabelInterpreter = 'latex';
cbPh.FontSize = fontSizeMetric;
ylabel(cbPh, '$\angle M_{xy}$', 'Interpreter','latex', 'fontsize', fontSizeMetric+2)
set(cbPh, 'YTick', -pi:pi/2:pi);
set(cbPh, 'YTickLabel', {'$-\pi$', '$\frac{-\pi}{2}$', '$0$', '$\frac{\pi}{2}$', '$\pi$'});

%% RF Pulse Diagram
axRFwaveform = nexttile( 2, [ 1 2 ] );
hold( axRFwaveform, 'on' );
for dd = 1:length(Waveform.dfxy)
    pRF = plot( tvec/1e-3,  abs(RFphasor(dd,:)));
    pRF.LineWidth = lineWidth;
    pRF.Color = '#009900';
    if dd == 2
        pRF.LineStyle = '-.';
    end
end
xlim( [0 tend/1e-3] );
ylim( [0 max(abs(abs(RFphasor)),[], 'all' )] );
grid(axRFwaveform, 'on');
axRFwaveform.TickLabelInterpreter='latex';
% axRFwaveform.FontSize = fontSizeAx;
ylabel('$|{\rm RF}|$ (V)', 'interpreter', 'latex');
title(['\textbf{', 'Pulse Sequence Diagram', '}'], 'interpreter', 'latex');

%% RF Freq Diagram
axFreqRFwaveform = nexttile( 5, [ 1 2 ]  );
hold( axFreqRFwaveform, 'on' );
for dd = 1:length(Waveform.dfxy)
    pRF = plot( tvec/1e-3,  Freq(dd,:)/1e3);
    pRF.LineWidth = lineWidth;
    pRF.Color = '#A2142F';
    if dd == 2
        pRF.LineStyle = '-.';
    end
end
xlim( [0 tend/1e-3] );
grid(axFreqRFwaveform, 'on');
axFreqRFwaveform.TickLabelInterpreter='latex';
% axRFwaveform.FontSize = fontSizeAx;
ylabel('$\Delta f_{xy}$ (kHz)', 'interpreter', 'latex');

%% Shim Pulse Diagram
axShimwaveform = nexttile( 8, [ 1 2 ]  );
hold( axShimwaveform, 'on' );
pShim = plot( tvec/1e-3,  Shim);
set(pShim, 'linewidth', lineWidth);
set(pShim, {'color'}, shimColors);
xlim( [0 tend/1e-3] );
grid(axShimwaveform, 'on');
axShimwaveform.TickLabelInterpreter='latex';
% axShimwaveform.FontSize = fontSizeAx;
ylabel('Shim (A)', 'interpreter', 'latex');

%% Grad Pulse Diagram
axGradwaveform = nexttile( 11, [ 1 2 ] );
hold( axGradwaveform, 'on' );
pGrad = plot( tvec/1e-3,  Grad/1e-3);
set(pGrad, 'linewidth', lineWidth);
set(pGrad, {'color'}, gradColors);
xlim( [0 tend/1e-3] );
grid(axGradwaveform, 'on');
ylabel('Gradient (mT/m)', 'interpreter', 'latex');
xlabel('Time (ms)', 'interpreter', 'latex')
legend('show', {'$G_x$','$G_y$','$G_z$'},...
    'interpreter', 'latex',...
    'location', 'northwest')
grid(axGradwaveform, 'on');
axGradwaveform.TickLabelInterpreter='latex';
% axGradwaveform.FontSize = fontSizeAx;

%% Add Text To Magnetization Plots
pause(0.5)
magPos = magAx.Position;
phPos = phAx.Position;
inBetweenPosition = [magPos(1), phPos(2)+phPos(4), magPos(3), magPos(2)-phPos(2)-phPos(4)];

NRMSEPos = [ inBetweenPosition(1) + ((1-1)/4) * inBetweenPosition(3), inBetweenPosition(2),...
    (1/4) * inBetweenPosition(3), inBetweenPosition(4)];
annotation('textbox', NRMSEPos,...
    'str', sprintf('NRMSE: %.1f\\%%', round(100*NRMSE,roundN)), ...
    'fontsize', fontSizeMetric,...
    'color', 'k',...
    'interpreter', 'latex',...
    'verticalalignment', 'middle',...
    'horizontalalignment', 'center',...
    'edgecolor', 'none');

FAPos = [ inBetweenPosition(1) + ((2-1)/4) * inBetweenPosition(3), inBetweenPosition(2),...
    (1/4) * inBetweenPosition(3), inBetweenPosition(4)];
annotation('textbox', FAPos,...
    'str', sprintf('Mean FA: %.2f$^\\circ$', round(FA,roundN)), ...
    'fontsize', fontSizeMetric,...
    'color', 'k',...
    'interpreter', 'latex',...
    'verticalalignment', 'middle',...
    'horizontalalignment', 'center',...
    'edgecolor', 'none')

FAstdPos = [ inBetweenPosition(1) + ((3-1)/4) * inBetweenPosition(3), inBetweenPosition(2),...
    (1/4) * inBetweenPosition(3), inBetweenPosition(4)];
annotation('textbox', FAstdPos,...
    'str', sprintf('SD FA: %.2f$^\\circ$',round(FAstd, roundN)), ...
    'fontsize', fontSizeMetric,...
    'color', 'k',...
    'interpreter', 'latex',...
    'verticalalignment', 'middle',...
    'horizontalalignment', 'center',...
    'edgecolor', 'none')

PowerPos = [ inBetweenPosition(1) + ((4-1)/4) * inBetweenPosition(3), inBetweenPosition(2),...
    (1/4) * inBetweenPosition(3), inBetweenPosition(4)];
annotation('textbox', PowerPos,...
    'str', sprintf('Pulse Pow.: %.2f W', round(GlobalPower,roundN)), ...
    'fontsize', fontSizeMetric,...
    'color', 'k',...
    'interpreter', 'latex',...
    'verticalalignment', 'middle',...
    'horizontalalignment', 'center',...
    'edgecolor', 'none')

%% Set figure window style back to default
if ~binVis
    set(groot, 'defaultfigurewindowstyle', dfws)
end

end