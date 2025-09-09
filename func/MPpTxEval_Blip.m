function [ mTot, fwdStruct ] = MPpTxEval_Blip(designParams, evalStruct, fwdModEval)
% This function will evaluate the small-tip angle approximation for the
% magnetization given the design parameters. We are assuming that there are
% three back-to-back subpulses. The first is the initial birdcage subpulse,
% the second is a z-directed field blip, and the third is the multiphoton pulse.
% We are assuming the z-directed fields are governed by cosinusoidal waveforms.
arguments
    designParams
    evalStruct
    fwdModEval = true
end

%% Load Params From Struct To Use Later
fwdStruct = struct;
fwdStruct.dwxy = evalStruct.dwxy;
fwdStruct.wz = evalStruct.wz;
fwdStruct.M0vec = evalStruct.M0vec;
fwdStruct.gyro = evalStruct.gyro;
fwdStruct.DB0Vec = evalStruct.DB0Vec;
fwdStruct.Mxyz = evalStruct.Mxyz;
fwdStruct.BxySensCoil = evalStruct.BxySensCoil;
fwdStruct.BzSensCoil = evalStruct.BzSensCoil;
numZCoils = evalStruct.numZCoils;

% Get timing parameters
fwdStruct.dt = evalStruct.dt;

fwdStruct.tORSP = evalStruct.tORSP;
fwdStruct.tendORSP = evalStruct.tendORSP;
fwdStruct.tvecORSP = evalStruct.tvecORSP;
% tMatORSP = evalStruct.tMatORSP;
% tMatGradORSP = evalStruct.tMatGradORSP;

fwdStruct.tBlip = evalStruct.tBlip;
fwdStruct.dt_tBlip = evalStruct.dt_tBlip;
fwdStruct.tendBlip = evalStruct.tendBlip;
fwdStruct.shimBlipSlewTime = evalStruct.shimBlipSlewTime;
fwdStruct.shimMPSPSlewTime = evalStruct.shimMPSPSlewTime;
fwdStruct.gradMPSPSlewTime = evalStruct.gradMPSPSlewTime;
% tvecBlip = evalStruct.tvecBlip;

fwdStruct.tMPSP = evalStruct.tMPSP;
fwdStruct.tendMPSP = evalStruct.tendMPSP;
fwdStruct.tvecMPSP = evalStruct.tvecMPSP;
fwdStruct.tMatMPSP = evalStruct.tMatMPSP;
fwdStruct.tMatGradMPSP = evalStruct.tMatGradMPSP;

%% Assign indexes for Slew if used for Fwd Eval
fwdStruct.Rise_Shim_i = evalStruct.Rise_Shim_i;
fwdStruct.Rise_Shim_f = evalStruct.Rise_Shim_f;
fwdStruct.Wave_Shim_i = evalStruct.Wave_Shim_i;
fwdStruct.Wave_Shim_f = evalStruct.Wave_Shim_f;
fwdStruct.Fall_Shim_i = evalStruct.Fall_Shim_i;
fwdStruct.Fall_Shim_f = evalStruct.Fall_Shim_f;

fwdStruct.Rise_Grad_i = evalStruct.Rise_Grad_i;
fwdStruct.Rise_Grad_f = evalStruct.Rise_Grad_f;
fwdStruct.Wave_Grad_i = evalStruct.Wave_Grad_i;
fwdStruct.Wave_Grad_f = evalStruct.Wave_Grad_f;
fwdStruct.Fall_Grad_i = evalStruct.Fall_Grad_i;
fwdStruct.Fall_Grad_f = evalStruct.Fall_Grad_f;

%% Load In Input Vec
designParams = designParams(:);

% Initial Birdcage Coil Phasor
fwdStruct.bcOR = designParams(1);
% Shim Coil Parameters
shimRealCoilVec = designParams( 1 + (1:2:2*numZCoils) );
shimImagCoilVec = designParams( 1 + (2:2:2*numZCoils) );
shimCoilPhasor = shimRealCoilVec + 1j*shimImagCoilVec;
fwdStruct.shimAmpCoilVec = abs(shimCoilPhasor);
fwdStruct.shimPhaseCoilVec = angle(shimCoilPhasor);
% Multiphoton Birdcage Coil Phasor
fwdStruct.bcMP = designParams(1+2*numZCoils + 1) + 1j * designParams(1+2*numZCoils + 2);
% Get Gradient Phasor Information
gradComp = designParams((1+2*numZCoils+3):2:(1+2*numZCoils+8)) + ...
    1j* designParams((1+2*numZCoils+4):2:(1+2*numZCoils+8));
fwdStruct.gradAmpVec = abs(gradComp);
fwdStruct.gradPhVec = angle(gradComp);
% Blip Magnitudes
fwdStruct.shimAmpBlip = designParams((1+2*numZCoils+9):1:(1+2*numZCoils+9+numZCoils-1));
fwdStruct.gradMagBlip = designParams((1+3*numZCoils+9):1:(1+3*numZCoils+11));
% MP Pulse Lengths
fwdStruct.shimTp = fwdStruct.tMPSP * ones( numZCoils, 1 );
fwdStruct.gradTp = fwdStruct.tMPSP * ones( 3, 1 );

%% Run Fwd Model
if fwdModEval
    mTot = evalStruct.fwdModEvalHandle( fwdStruct );
else
    mTot = 0;
end

end