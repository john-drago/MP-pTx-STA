function CompFig = plotFwdSimComparison(MP, binVis)
% Function that will plot the comparison between the forward model and the
% simulation that is performed by BlochSimulation in the Larmor rotating frame.
% We expect error on the order of .1 degrees. We will plot each plot on its
% own color scale.
arguments
    MP
    binVis = true;
end

%% Initialize Variables for Plotting
percHorzReduce = 0.25; % first index is horizontal
percVertReduce = 0.05; % second index is vertical

%% Get Slice Idxs 
numImgs = 20;
sliceIdx = sliceIdxNumImgs( numImgs, MP.Val.roi_brain_planes );

%% Create the Arrays Needed to Use plotMultipleArrays Function
Mmpptx_xy3Dplanes = MP.Val.Mmpptx_xy3Dplanes( :, :, sliceIdx );
Mmpptxfwd_xy3Dplanes = MP.Val.Mmpptxfwd_xy3Dplanes( :, :, sliceIdx );

MmpptxError_xy3Dplanes = abs(abs(Mmpptx_xy3Dplanes) - abs(Mmpptxfwd_xy3Dplanes)) .*...
    exp(1j* (angle(Mmpptx_xy3Dplanes) - angle(Mmpptxfwd_xy3Dplanes)));

cellOfArrays = {...
    Mmpptx_xy3Dplanes,...
    Mmpptxfwd_xy3Dplanes,...
    MmpptxError_xy3Dplanes};

cellOfLabels = {...
    'Bloch Sim',...
    'Fwd Model',...
    'Error'};

%% Plot Comparison Figure
% localCLimMaxScalingFlag = true;
localCLimMaxScalingFlag = round( 7 * sin( MP.opt.FAtarg ), 1) / 4; % round to nearest 0.05
CompFig = plotMultipleArrays(cellOfArrays, cellOfLabels,...
    binVis, [], localCLimMaxScalingFlag, percHorzReduce, percVertReduce);

%% Add ROI (Brain) Outline to Fig
% We do it this way so that the error is shown globablly and not just in
% the ROI, but we still want the ROI to be highlighted to see where the
% errors are occurring
outlineLineWidth = 1.75;
BrainOutline = rearrangeCutImgStack(...
    MP.Val.roi_brain_planes(:,:,sliceIdx), percHorzReduce, percVertReduce);

tl = CompFig.Children;

for pp = 1:prod(tl.GridSize)
    currAx = nexttile(tl, pp);
    cLim = currAx.CLim;
    hold(currAx, 'on');
    [~, contMagAx] =  imcontour( fliplr(permute( BrainOutline, [2 1] )), 1);
    contMagAx.Color = 'w';
    contMagAx.LineWidth = outlineLineWidth;
    currAx.CLim = cLim;
end

end