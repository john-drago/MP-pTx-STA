%% File Description
% This file runs an example MP-pTx optimization.
%
% This code repository aims to demonstrate the MP-pTx small-tip angle
% optimization process -- specifically the forward model evaluation
% process, which underlies the optimization.
%
% (c) John M. Drago, 2023-2024.
% MIT License

%% File preliminaries
clear;
% close all;
home;

%% Set file paths
restoredefaultpath;
currDir = fileparts( mfilename( 'fullpath' ) );
addpath( fullfile( currDir, 'func' ) );
dataDir = normalizePath( fullfile( currDir, '..', 'data' ) );
addpath( dataDir );

%% Load Fields
b1p = load( fullfile( dataDir, 'birdcage_fields.mat' ) );
bs = load( fullfile( dataDir, '32ch_fields.mat' ) );
db0 = load( fullfile( dataDir, 'db0_fields.mat' ) );
rngState = load( fullfile( dataDir, 'rng_state.mat' ) );

%% Optimization Initialization
useParallel = true;
usePrev = true;

optInit = struct;
optInit.optType = 'ga';
optInit.gaNumGen = 20;
optInit.gaPopSize = 1000;
optInit.fminIter = 200;

if usePrev
    optInit.rngstate.State = rngState.rngState;
end

optInit.fminopt = initfMinOptStruct( optInit.fminIter );
optInit.fminopt.UseParallel = useParallel;
optInit.fminopt.StepTolerance = 1e-6;
optInit.fminopt.FiniteDifferenceStepSize = 1e-7;
optInit.fminopt.Algorithm = "sqp";

optInit.gaopt = initGAOptStruct( optInit.gaPopSize, optInit.gaNumGen );
optInit.gaopt.UseParallel = useParallel;
optInit.gaopt.MutationFcn = 'mutationpower';

optInit.fwdModName = 'Blip';
optInit.fwdModEval = 'slew';

optInit.costfn = @MPpTxCost;

optInit.BzBound = 50; % Amp-turns
optInit.shimBlipBound = 15; % Amp-turns

optInit.gradSlewRateLimit = 200; % T/(m*s)
optInit.gradMagScale = 25e-3;
optInit.gradMagBlip = 5e-3;

optInit.BxyBCSPBound = 175;
optInit.BxyMPSPBound = 175;

%% MP-pTx Pulse Specification
inpSt = struct;
inpSt.dfxy = 10e3;
inpSt.fz = 10e3;
inpSt.dxinterp = 0.005;
inpSt.dyinterp = 0.005;
inpSt.dzinterp = 0.005;
inpSt.tORSP = 0.25e-3;
inpSt.tBlip = 0.25e-3;
inpSt.tMPSP = 0.50e-3;
inpSt.FAtargDeg = 10;

%% Run Opt
numCores = 8;
if useParallel && isempty(gcp('nocreate')) 
    myCluster = parcluster('local');
    parpool( min([ numCores, myCluster.NumWorkers] ) );
end

MP = optControl(...
    optInit, inpSt, bs, b1p, db0);

%% Plot Opt results
binVis = true;
[ shimFig, fieldsFig, psdFig, bcCompFig, fwdSimCompFig ] =...
    plotOptResults( MP, bs, b1p, db0, binVis );
