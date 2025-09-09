function fieldsFig = plotOptFields( MP, b1p, db0, binVis )

numImgs = 20;
sliceIdx = sliceIdxNumImgs( numImgs, MP.Val.roi_brain_planes );

[ ~, ~, KK ] = ndgrid( 1:length(b1p.x), 1:length(b1p.y), 1:length(b1p.z) );
zi = unique( KK( b1p.roi_brain ) );

cAx_b1p = [ 0, 30 ]; % nT/A
cAx_db0 = [ -200, 200 ]; % Hz
cmap_b1p = colorcet( 'L08' );
cmap_db0 = colorcet( 'D01' );
gyro = 267.5e6;

b1p_planes = 1e9 * abs( b1p.b1p( :, :, zi ) );
db0_planes = gyro/(2*pi) * db0.db0( :, :, zi );
roi_planes = MP.Val.roi_brain_planes;

b1p_slices = rearrangeCutImgStack( b1p_planes( :, :, sliceIdx ) );
db0_slices = rearrangeCutImgStack( db0_planes( :, :, sliceIdx ) ); 
roi_slices = rearrangeCutImgStack( roi_planes( :, :, sliceIdx ) );

% specify images
contCol_b1p = 'w';
contCol_db0 = 'k';
outlineLineWidth = 1.75;
figSize = [ 1 1 1450 450 ];

if binVis
    fieldsFig = figure('color', 'white',...
        'Visible','on');
else
    dfws = get(groot, 'defaultfigurewindowstyle');
    set(groot, 'defaultfigurewindowstyle','normal')
    fieldsFig = figure('color', 'white',...
        'Visible','off','position', figSize);
end

pause(0.5);
tiledlayout( 1, 2, 'padding', 'compact' );
pause(0.5);

% B1p
ax = nexttile( 1 );
hold( ax, 'on' );
imagesc( ax, permute( b1p_slices, [2 1] ) );
set( ax, 'ydir', 'normal' );
axis( ax, 'image' );
xticklabels( ax, [] );
yticklabels( ax, [] );
clim( ax, cAx_b1p );
colormap( ax, cmap_b1p );
[~, contMagAx] =  imcontour( permute( roi_slices, [2 1] ), 1);
contMagAx.Color = contCol_b1p;
contMagAx.LineWidth = outlineLineWidth;
cbMag = colorbar(ax);
cbMag.TickLabelInterpreter = 'latex';
ylabel(cbMag, '$B_1^+$ [nT/V]', 'Interpreter','latex');
title( ax, '\textbf{ $|B_1^+|$ Fieldmap }', 'interpreter', 'latex' );
pause(0.1);

% dB0
ax = nexttile( 2 );
hold( ax, 'on' );
imagesc( ax, permute( db0_slices, [2 1] ) );
set( ax, 'ydir', 'normal' );
axis( ax, 'image' );
xticklabels( ax, [] );
yticklabels( ax, [] );
clim( ax, cAx_db0 );
colormap( ax, cmap_db0 );
[~, contMagAx] =  imcontour( permute( roi_slices, [2 1] ), 1);
contMagAx.Color = contCol_db0;
contMagAx.LineWidth = outlineLineWidth;
cbMag = colorbar(ax);
cbMag.TickLabelInterpreter = 'latex';
ylabel(cbMag, '$\Delta B_0$ [Hz]', 'Interpreter','latex');
title( ax, '\textbf{ $\Delta B_0$ Fieldmap }', 'interpreter', 'latex' );
pause(0.1);


if ~binVis % change default figure window style back to original
    set(groot, 'defaultfigurewindowstyle', dfws)
end

end