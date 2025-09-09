function MosaicFig = plotMultipleArrays(cellOfArrays, cellOfLabels,...
    binVis, roiFOV, localScalingFlag, percHorzReduce, percVertReduce)
% Function that will plot multiple magnetization arrays. The expected data
% format is a cell array of the 3D arrays of magnetization (complex) data.
% The titles of the arrays should also be included in a cell array that
% contains strings as the entries.
arguments
    cellOfArrays
    cellOfLabels % Cell array or string array of labels for the different images
    binVis = true; % whether or not to make the figures visible
    roiFOV = []; % logical ROI for contour plotting
    localScalingFlag = true; % whether to scale the coloraxis of each plot
    % individually, can pass logical or a numeric value
    percHorzReduce = 0.25; % first index is horizontal
    percVertReduce = 0.05; % second index is vertical
end

%% Ensure that the number of arrays matches the number of labels
numOfArrays = length(cellOfArrays);
numOfLabels = length(cellOfLabels);

if numOfArrays~=numOfLabels
    error('Error in Number of Labels')
end

cellOfLabels = string( cellOfLabels ) ;

%% Set Image Attributes
fontSizeAx = 24;
outlineLineWidth = 1.75;

phasem = phasemap(256);
% phasem = colorcet('C1');

% magm = parula(256);
magm = colorcet('L09');

%% Determine if we should perform local scaling
% in other words, scale every image to its local values
if localScalingFlag == 1
    localScalingFlag = true;
elseif localScalingFlag == 0
    localScalingFlag = false;
end

%% Determine if there is a ROI contour that we should plot
contourBin = ~isempty(roiFOV);
if contourBin
    ROIOutline = rearrangeCutImgStack(logical(roiFOV), percHorzReduce, percVertReduce);
end

%% Adust color limits if contour is passed
% If there is an ROI, we will always scale to the points within the ROI
if isa(localScalingFlag, 'logical')
    if localScalingFlag
        cMax = zeros( 1, numOfArrays );
        maxVal = 0;
        for nn = 1:numOfArrays
            CompImgStack = cellOfArrays{nn};
            if contourBin
                cMax(nn) = max([max(abs(CompImgStack(roiFOV)), [], 'all'), maxVal]);
            else
                cMax(nn) = max([max(abs(CompImgStack), [], 'all'), maxVal]);
            end

            % Check to see if color max is 0
            if cMax(nn) == 0
                cMax(nn) = 1e-6;
            end
        end
    else
        maxVal = 0;
        for nn = 1:numOfArrays
            CompImgStack = cellOfArrays{nn};
            if contourBin
                maxVal = max([max(abs(CompImgStack(roiFOV)), [], 'all'), maxVal]);
            else
                maxVal = max([max(abs(CompImgStack), [], 'all'), maxVal]);
            end
        end
        % Check to see if color max is 0
        if maxVal == 0
            maxVal = 1e-6;
        end
        cMax = maxVal * ones(1, numOfArrays);
    end

    cMax = cMax * 1.025; % increase colorbar by 2.5%
elseif isa(localScalingFlag, 'numeric')
    cMax = localScalingFlag * ones(1, numOfArrays);
end

%% Start Plotting
% determine if figure should be visible or not
if binVis
    MosaicFig = figure('color', 'white', 'Units', 'pixels',...
        'Visible','on');
else
    dfws = get(groot, 'defaultfigurewindowstyle');
    set(groot, 'defaultfigurewindowstyle','normal')
    MosaicFig = figure('color', 'white', 'Units', 'pixels',...
        'Visible','off','position', [1 1 1750 1000]);
end
pause(0.1)

%% Commence Plotting
% Determine the number of tiled layouts from the cell array
tiledlayout(2,numOfArrays, 'TileSpacing','compact', 'Padding','compact');
for nn = 1:numOfArrays

    CompImgStack = cellOfArrays{nn};
    CompImg = rearrangeCutImgStack(CompImgStack, percHorzReduce, percVertReduce);

    magAx(nn) = nexttile(nn); %#ok
    hold(magAx(nn), 'on');
    imagesc( magAx(nn), fliplr(permute(abs(CompImg) ,[2 1])));
    set(magAx(nn), 'ydir', 'normal');
    axis(magAx(nn), 'image');
    xticklabels([]);
    yticklabels([]);
    caxis(magAx(nn), [0, cMax(nn)]); %#ok<*CAXIS>
    colormap(magAx(nn), magm)
    if contourBin
        [~, contMagAx] =  imcontour( fliplr(permute( ROIOutline, [2 1] )), 1);
        contMagAx.Color = 'w';
        contMagAx.LineWidth = outlineLineWidth;
    end
    pause(0.2)

    if nn == numOfArrays  || ( isa(localScalingFlag, 'logical') && localScalingFlag)
        cbMag = colorbar(magAx(nn));
        cbMag.TickLabelInterpreter = 'latex';
        cbMag.FontSize = fontSizeAx-4;
        ylabel(cbMag, '$|M_{xy}|$', 'Interpreter','latex', 'fontsize', fontSizeAx)
        pause(0.2)
    end

    phAx(nn) = nexttile(nn+numOfArrays);%#ok
    hold(phAx(nn), 'on');
    imagesc( phAx(nn), fliplr(permute( angle(CompImg) ,[2 1])));
    set(phAx(nn), 'ydir', 'normal');
    axis(phAx(nn), 'image');
    xticklabels([]);
    yticklabels([]);
    caxis(phAx(nn),  [-pi, pi]);
    colormap(phAx(nn), phasem)
    if contourBin
        [~, contPhAx] =  imcontour( fliplr(permute( ROIOutline, [2 1] )), 1);
        contPhAx.Color = 'w';
        contPhAx.LineWidth = outlineLineWidth;
    end
    pause(0.2)

    if nn == numOfArrays  || ( isa(localScalingFlag, 'logical') && localScalingFlag)
        cbPh = colorbar(phAx(nn));
        cbPh.TickLabelInterpreter = 'latex';
        cbPh.FontSize = fontSizeAx;
        ylabel(cbPh, '$\angle M_{xy}$', 'Interpreter','latex', 'fontsize', fontSizeAx)
        set(cbPh, 'YTick', -pi:pi/2:pi);
        set(cbPh, 'YTickLabel', {'$-\pi$', '$\frac{-\pi}{2}$', '$0$', '$\frac{\pi}{2}$', '$\pi$'});
        pause(0.2)
    end

end

%% Plot Titles of the the different arrays
% Will do this at the end so that the different plots are settled, and the
% text doesn't have to be readjusted
for nn = 1:numOfArrays
    labelStr = cellOfLabels(nn);

    title( magAx(nn), ['\textbf{',char(labelStr), '}'],...
        'interpreter', 'latex');
    pause(0.2);
end

%% Finish Plotting
if ~binVis % change default figure window style back to original
    set(groot, 'defaultfigurewindowstyle', dfws)
end

end