function [imgOptFig] = plotBirdcageComparison(MP, binVis)
arguments
    MP
    binVis = false
end

%% Get Structs
Val = MP.Val;
opt = MP.opt;

%% Initialize variables
percHorzReduce = 0.25; % first index is horizontal
percVertReduce = 0.05; % second index is vertical
roundN = 3;
numFigsToPlot = 2;
fontSizeMetric = 14;
outlineLineWidth = 1.75;

phasem = phasemap(256);
magm = colorcet('L09');

%% Determine Which Arrays to Use (Fwd vs. Bloch Sim) for Plotting
MBC_xy3Dplanes = Val.MBC_xy3Dplanes;
Mmpptx_xy3Dplanes = Val.Mmpptx_xy3Dplanes;

%% Determine Which planes to Use
numImgs = 20;
sliceIdx = sliceIdxNumImgs( numImgs, Val.roi_brain_planes );

%% Pre plot computations

cMagMax = round( 4 * sin( opt.FAtarg ), 1) / 2; % round to nearest 0.05
cMagAx = [0, cMagMax];

%% Initialize Figure
if binVis
    imgOptFig = figure('color', 'white', 'Units', 'pixels',...
        'Visible','on');
else
    dfws = get(groot, 'defaultfigurewindowstyle');
    set(groot, 'defaultfigurewindowstyle','normal')
    imgOptFig = figure('color', 'white', 'Units', 'pixels',...
        'Visible','off','position', [1 1 1750 1000]);
end

tl = tiledlayout(2, numFigsToPlot,...
    'TileSpacing','compact', 'Padding', 'compact'); %#ok

%% Get roiFOVplanes. Do some erosion and dilation to get contiguous ROI maps
% % Do some erosion and dilation to make the ROI maps smoother
% [xx,yy,zz] = ndgrid(-3:3, -3:3, -3:3);
% nhood = (sqrt(xx.^2 + yy.^2 + 0.^2) <= 2.0) & (zz == 0);
% % Dilation
% roiFOVplanes = imdilate(Val.roiFOVbody_planes, nhood);
% % Erosion
% roiFOVplanes = imerode(roiFOVplanes, nhood); 

roiBrainPlanes = Val.roi_brain_planes;
roiBrainPlanes = roiBrainPlanes( :, :, sliceIdx );

%% Start Plotting Loop
% Plot initially the images and then we will loop back and plot the text
for nn = 1:numFigsToPlot

    if nn == 1
        Mplanesiter = MBC_xy3Dplanes;
    elseif nn == 2
        Mplanesiter = Mmpptx_xy3Dplanes;
    end
    
    % Only show a subset of slices so that image can be comprehended
    Mplanesiter = Mplanesiter( :, :, sliceIdx );
    
    % Create the mosaics
    CompImg = rearrangeCutImgStack(Mplanesiter, percHorzReduce, percVertReduce);
    BrainOutline = rearrangeCutImgStack(roiBrainPlanes, percHorzReduce, percVertReduce);

    magAx(nn) = nexttile(nn); %#ok 
    hold(magAx(nn), 'on');
    imagesc( magAx(nn), fliplr(permute( abs(CompImg) ,[2 1])));
    set(magAx(nn), 'ydir', 'normal');
    axis(magAx(nn), 'image');
    xticklabels([]);
    yticklabels([]);
    caxis(magAx(nn), cMagAx); %#ok 
    colormap(magAx(nn), magm)
    [~, contMagAx] =  imcontour( fliplr(permute( BrainOutline, [2 1] )), 1);
    contMagAx.Color = 'w';
    contMagAx.LineWidth = outlineLineWidth;
    set(magAx(nn), 'visible', 'off')
    pause(0.1)
    if nn==2
        cbMag = colorbar(magAx(nn));
        cbMag.TickLabelInterpreter = 'latex';
        cbMag.FontSize = fontSizeMetric-2;
        ylabel(cbMag, '$|M_{xy}|$', 'Interpreter','latex', 'fontsize', fontSizeMetric)
    end
    pause(0.1)

    phAx(nn) = nexttile(nn+numFigsToPlot);%#ok
    hold(phAx(nn), 'on');
    imagesc( phAx(nn), fliplr(permute( angle(CompImg) ,[2 1])));
    set(phAx(nn), 'ydir', 'normal');
    axis(phAx(nn), 'image');
    xticklabels([]);
    yticklabels([]);
    caxis(phAx(nn),  [-pi, pi]); %#ok
    colormap(phAx(nn), phasem)
    [~, contPhAx] =  imcontour( fliplr(permute( BrainOutline, [2 1] )), 1);
    contPhAx.Color = 'w';
    contPhAx.LineWidth = outlineLineWidth;
    set(phAx(nn), 'visible', 'off')
    pause(0.1)
    if nn==2
        cbPh = colorbar(phAx(nn));
        cbPh.TickLabelInterpreter = 'latex';
        cbPh.FontSize = fontSizeMetric;
        ylabel(cbPh, '$\angle M_{xy}$', 'Interpreter','latex', 'fontsize', fontSizeMetric)
        set(cbPh, 'YTick', -pi:pi/2:pi);
        set(cbPh, 'YTickLabel', {'$-\pi$', '$\frac{-\pi}{2}$', '$0$', '$\frac{\pi}{2}$', '$\pi$'});
    end
    pause(0.1)
end

% Plot the text loop
for nn = 1:numFigsToPlot

    if nn == 1
        labelStr = 'Birdcage Alone';
    elseif nn == 2
        labelStr = 'MPpTx';
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Annotation
    magPos = magAx(nn).Position;
    phPos = phAx(nn).Position;
    pause(0.1)

    titleBox = [magPos(1), magPos(2)+magPos(4), magPos(3), 0.25*magPos(2)+magPos(4)];
    annotation('textbox', titleBox,...
        'str', ['\textbf{',labelStr, '}'], ...
        'fontsize', fontSizeMetric+4,...
        'color', 'k',...
        'interpreter', 'latex',...
        'verticalalignment', 'bottom',...
        'horizontalalignment', 'center',...
        'edgecolor', 'none')

    inBetweenPosition = [magPos(1), phPos(2)+phPos(4), magPos(3), magPos(2)-phPos(2)-phPos(4)];

    numAnnotations = 4;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NRMSE Plot
    NRMSEPos = [ inBetweenPosition(1) + ((1-1)/4) * inBetweenPosition(3), inBetweenPosition(2),...
        (1/4) * inBetweenPosition(3), inBetweenPosition(4)];

    if nn == 1
        NRMSEtot = opt.BC_magNRMSE;
    elseif nn == 2
        NRMSEtot = opt.mpptx_magNRMSE;
    end
    annotation('textbox', NRMSEPos,...
    'str', sprintf('NRMSE: %.1f\\%%', round(100*NRMSEtot,roundN)), ...
    'fontsize', fontSizeMetric,...
    'color', 'k',...
    'interpreter', 'latex',...
    'verticalalignment', 'middle',...
    'horizontalalignment', 'center',...
    'edgecolor', 'none');

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Mean FA
    FAPos = [ inBetweenPosition(1) + ((2-1)/4) * inBetweenPosition(3), inBetweenPosition(2),...
        (1/4) * inBetweenPosition(3), inBetweenPosition(4)];

    if nn == 1
        FAmean = opt.BC_FAMean;
    elseif nn == 2
        FAmean = opt.mpptx_FAMean;
    end
    annotation('textbox', FAPos,...
    'str', sprintf('Mean FA: %.2f$^\\circ$', round(FAmean,roundN)), ...
    'fontsize', fontSizeMetric,...
    'color', 'k',...
    'interpreter', 'latex',...
    'verticalalignment', 'middle',...
    'horizontalalignment', 'center',...
    'edgecolor', 'none');


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Std FA
    FAstdPos = [ inBetweenPosition(1) + ((3-1)/4) * inBetweenPosition(3), inBetweenPosition(2),...
        (1/4) * inBetweenPosition(3), inBetweenPosition(4)];

    if nn == 1
        FAstd = opt.BC_FAStd;
    elseif nn == 2
        FAstd = opt.mpptx_FAStd;
    end
    annotation('textbox', FAstdPos,...
        'str', sprintf('SD FA: %.2f$^\\circ$',round(FAstd, roundN)), ...
        'fontsize', fontSizeMetric,...
        'color', 'k',...
        'interpreter', 'latex',...
        'verticalalignment', 'middle',...
        'horizontalalignment', 'center',...
        'edgecolor', 'none')

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Pulse Power
    PowerPos = [ inBetweenPosition(1) + ((4-1)/4) * inBetweenPosition(3), inBetweenPosition(2),...
        (1/4) * inBetweenPosition(3), inBetweenPosition(4)];

    if nn == 1
        pulsePower = opt.BC_PulsePower;
    elseif nn == 2
        pulsePower = opt.mpptx_PulsePower;
    end
    annotation('textbox', PowerPos,...
        'str', sprintf('Pulse Pow.: %.2f W', round(pulsePower,roundN)), ...
        'fontsize', fontSizeMetric,...
        'color', 'k',...
        'interpreter', 'latex',...
        'verticalalignment', 'middle',...
        'horizontalalignment', 'center',...
        'edgecolor', 'none');

    if ~binVis % change default figure window style back to original
        set(groot, 'defaultfigurewindowstyle', dfws)
    end

end

end