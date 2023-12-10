function [ shimFig, fieldsFig, psdFig, bcCompFig, fwdSimCompFig ] =...
    plotOptResults( MP, bs, b1p, db0, binVis )

pauseTime = 0.5;

%% Plot coils that are used in optimization process
shimFig = plotShimCoils( bs, binVis );
pause(pauseTime);

%% Plot B1p and DB0 fields
fieldsFig = plotOptFields( MP, b1p, db0, binVis );
pause(pauseTime);

%% Plot PSD
cMax = 0.3;
psdFig = plotPSD( MP, binVis, cMax );
pause(pauseTime);

%% Plot Birdcage Comparison
bcCompFig = plotBirdcageComparison( MP, binVis );
pause(pauseTime);

%% Plot Fwd Sim Comparison
fwdSimCompFig = plotFwdSimComparison( MP, binVis );

end