function coilFig = plotShimCoils( bs, binVis )

% Calculate positions
Xp = permute( bs.X, [2 1 3] )*1000;
Yp = permute( bs.Y, [2 1 3] )*1000;
Zp = permute( bs.Z, [2 1 3] )*1000;

roi_body_p = permute( double(bs.roi_body), [2 1 3] );

numOfArrows = 5;    
arrowScale = 10;
facealp = 0.7;
% facecol = '#FF9999';
facecol = 'g';
% linecol = '#74009E';
linecol = 'r';
lineWidth = 2;
tipSz = 20;
tipCol = 'g';

xLim = [ -150, 150 ];
yLim = [ -140, 160 ];
zLim = [ -200, 200 ];
sliceFaceAlpha = 1;

figSize = [ 1 1 1825 515 ];

if binVis
    coilFig = figure('color', 'white',...
        'Visible','on');
else
    dfws = get(groot, 'defaultfigurewindowstyle');
    set(groot, 'defaultfigurewindowstyle','normal')
    coilFig = figure('color', 'white',...
        'Visible','off','position', figSize);
end

tl = tiledlayout( 1, 1, 'padding', 'compact', 'tilespacing', 'compact' );

% first axis: coronal
ax1 = nexttile( tl, 1 );
hold( ax1, 'on' );

s = slice( ax1, Xp, Yp, Zp, roi_body_p, 0, 0, 0 );
set(s, 'edgecolor' , 'none');
set(s, 'facealpha' , sliceFaceAlpha);

for cc=1:bs.coilNum

    coilIdxs = bs.coilIdxs(:,cc);
    
    arrowIdxs = (0:numOfArrows-1)*ceil(abs(diff(coilIdxs))/(numOfArrows))+1;

    segPos = 1000*bs.segPos(:, coilIdxs(1):coilIdxs(2));
    segLeg = 1000*bs.segLength(:, coilIdxs(1):coilIdxs(2));
    segEnd = 1000*bs.segPos(:, coilIdxs(2))+bs.segLength(:,coilIdxs(2));
    segTot = [segPos, segEnd];
    plot3( ax1, segTot(1,:), segTot(2,:), segTot(3,:), ...
        'linewidth', lineWidth, 'color', linecol)

    for aa=1:length(arrowIdxs)
        arStPos = segPos( :, arrowIdxs(aa) );
        arStVec = segLeg( :, arrowIdxs(aa) );

        arBaseBasis = null(arStVec');

        basePoints = arBaseBasis*[ 0.5,  0.5, -0.5,  -0.5;...
                                  0.5, -0.5,  0.5,  -0.5];
        basePoints = arrowScale*norm(arStVec)*basePoints./(vecnorm(basePoints, 2, 1))...
            + arStPos;
        pyrPoints = [basePoints, arStPos + arStVec*arrowScale*1.5];

        baseFace = [  1,  2,  4,  3,   1];
        bF = patch(ax1, 'Faces', baseFace, 'Vertices', basePoints',...
            'facealpha', facealp, 'facecolor', facecol); %#ok<*NASGU> 
        pyrFace = [  1,  5,  2,  1;...
                     2,  5,  4,  2;...
                     3,  5,  4,  3;...
                     1,  5,  3,  1]';
        pF = patch( ax1, 'Faces', pyrFace', 'Vertices', pyrPoints',...
            'facealpha', facealp, 'facecolor', facecol);
    end
end

xlabel(ax1, '$x$ Direction (mm)', 'interpreter', 'latex');
ylabel(ax1, '$y$ Direction (mm)', 'interpreter', 'latex')
zlabel(ax1, '$z$ Direction (mm)', 'interpreter', 'latex')
grid(ax1, 'on');
axis(ax1, 'equal');
set(ax1, 'zdir', 'reverse');
set(ax1, 'ydir', 'reverse');

xlim( ax1, xLim );
ylim( ax1, yLim );
zlim( ax1, zLim );

ax1.CameraPosition = 1e3 *...
    [ 2.509912607715085, 0.952955213053682, -1.145065136927915 ];

title( tl, '\textbf{Shim Coil Position}',...
    'interpreter', 'latex', 'fontsize', 25 );

if ~binVis % change default figure window style back to original
    set(groot, 'defaultfigurewindowstyle', dfws)
end

end