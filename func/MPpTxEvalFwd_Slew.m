function mTot = MPpTxEvalFwd_Slew( fwdStruct )
% This function will evaluate the small-tip angle approximation for the
% magnetization given the design parameters. We are assuming that there are
% three back-to-back subpulses. The first is the initial birdcage subpulse,
% the second is a z-directed field blip, and the third is the multiphoton pulse.
% We are assuming the z-directed fields are governed by cosinusoidal waveforms.

%% Load Params From Struct To Use Later
%% Base Parameters
dwxy = fwdStruct.dwxy;
wz = fwdStruct.wz;
M0vec = fwdStruct.M0vec;
gyro = fwdStruct.gyro;
DB0Vec = fwdStruct.DB0Vec;
Mxyz = fwdStruct.Mxyz;
BxySensCoil = fwdStruct.BxySensCoil;
BzSensCoil = fwdStruct.BzSensCoil;
%% Get timing parameters
dt = fwdStruct.dt;
% ORSP
% tendORSP = fwdStruct.tendORSP;
tvecORSP = fwdStruct.tvecORSP;
% tMatORSP = fwdStruct.tMatORSP;
% tMatGradORSP = fwdStruct.tMatGradORSP;
% Blip
tendBlip = fwdStruct.tendBlip;
shimBlipSlewTime = fwdStruct.shimBlipSlewTime;
shimMPSPSlewTime = fwdStruct.shimMPSPSlewTime;
gradMPSPSlewTime = fwdStruct.gradMPSPSlewTime;
% tvecBlip = fwdStruct.tvecBlip;
% dt_tBlip = fwdStruct.dt_tBlip;
tBlip = fwdStruct.tBlip;
% MPSP
tendMPSP = fwdStruct.tendMPSP;
tvecMPSP = fwdStruct.tvecMPSP;
tMatMPSP = fwdStruct.tMatMPSP;
tMatGradMPSP = fwdStruct.tMatGradMPSP;

%% Get indices for Slew
Rise_Shim_i = fwdStruct.Rise_Shim_i;
Rise_Shim_f = fwdStruct.Rise_Shim_f;
Wave_Shim_i = fwdStruct.Wave_Shim_i;
Wave_Shim_f = fwdStruct.Wave_Shim_f;
Fall_Shim_i = fwdStruct.Fall_Shim_i;
Fall_Shim_f = fwdStruct.Fall_Shim_f;

Rise_Grad_i = fwdStruct.Rise_Grad_i;
Rise_Grad_f = fwdStruct.Rise_Grad_f;
Wave_Grad_i = fwdStruct.Wave_Grad_i;
Wave_Grad_f = fwdStruct.Wave_Grad_f;
Fall_Grad_i = fwdStruct.Fall_Grad_i;
Fall_Grad_f = fwdStruct.Fall_Grad_f;

%% Load Input Parameters
% Initial Birdcage Coil Phasor
bcOR = fwdStruct.bcOR;
% Shim Coil Parameters
shimPhasorMag = fwdStruct.shimAmpCoilVec;
shimPhasorPh = fwdStruct.shimPhaseCoilVec;
% Multiphoton Birdcage Coil Phasor
bcMP = fwdStruct.bcMP;
% Get Gradient Phasor Information
gradPhasorMag = fwdStruct.gradAmpVec;
gradPhasorPh = fwdStruct.gradPhVec;
% Blip Magnitudes
shimAmpBlip = fwdStruct.shimAmpBlip;
gradMagBlip = fwdStruct.gradMagBlip;
% Coil Pulse Lengths
% shimTp = fwdStruct.shimTp;
% gradTp = fwdStruct.gradTp;
% Put Coil Pulse Lengths into correct time period
% tendMPSP_shimTp = tendBlip + shimTp;
% tendMPSP_gradTp = tendBlip + gradTp;

%% Determine Where Intersection Points Are
if (wz~=0)
    shimSlewMPSPRise = shimPhasorMag .*...
        cos( wz * shimMPSPSlewTime + shimPhasorPh );
    shimSlewMPSPFall = shimPhasorMag .*...
        cos( wz * (tendMPSP - tendBlip - shimMPSPSlewTime) + shimPhasorPh );
    shimSlewMPSPRiseInt = (shimPhasorMag/wz) .*...
        sin( wz * shimMPSPSlewTime + shimPhasorPh );
    shimSlewMPSPFallInt = (shimPhasorMag/wz) .*...
        sin( wz * (tendMPSP - tendBlip - shimMPSPSlewTime) + shimPhasorPh );
    
    gradSlewMPSPRise = gradPhasorMag   .*...
        cos( wz * gradMPSPSlewTime + gradPhasorPh );
    gradSlewMPSPFall = gradPhasorMag .*...
        cos( wz * (tendMPSP - tendBlip - gradMPSPSlewTime) + gradPhasorPh );
    gradSlewMPSPRiseInt = (gradPhasorMag/wz) .*...
        sin( wz * gradMPSPSlewTime + gradPhasorPh );
    gradSlewMPSPFallInt = (gradPhasorMag/wz) .*...
        sin( wz * (tendMPSP - tendBlip - gradMPSPSlewTime) + gradPhasorPh );
else
    shimSlewMPSPRise = zeros( size(shimPhasorMag,1), 1 );
    shimSlewMPSPFall = zeros( size(shimPhasorMag,1), 1 );
    shimSlewMPSPRiseInt = zeros( size(shimPhasorMag,1), 1 );
    shimSlewMPSPFallInt = zeros( size(shimPhasorMag,1), 1 );
    
    gradSlewMPSPRise = zeros(3,1);
    gradSlewMPSPFall = zeros(3,1);
    gradSlewMPSPRiseInt = zeros(3,1);
    gradSlewMPSPFallInt = zeros(3,1);
end

%% First Part of Split Definite Integral from Low-Flip Angle Equation
% On-Resonance Excitation
% ΔB0 evolution
initBC_DB0 = DB0Vec * ( tvecORSP - tendMPSP );

% Phase due to Blip Period
% Assume trapezoidal shim blip
initBC_Shim_Blip = BzSensCoil * ( -shimAmpBlip * (tBlip - shimBlipSlewTime) );
% integrate triangle waveform for gradient blip
initBC_Grad_Blip = Mxyz * ( - (tBlip/2) * ( gradMagBlip ) );

% Integrate phase due to sinusoidal MPSP Fields
if  ( shimMPSPSlewTime ~= 0 ) && (wz ~= 0)
    
    initBC_Shim_MPSP_Rise = shimSlewMPSPRise * shimMPSPSlewTime / 2;
    initBC_Shim_MPSP_Wave = ( shimSlewMPSPFallInt - shimSlewMPSPRiseInt );
    initBC_Shim_MPSP_Fall = shimSlewMPSPFall * shimMPSPSlewTime / 2;
    initBC_Shim_MPSP = BzSensCoil * ( -1 * ( ...
        initBC_Shim_MPSP_Rise + initBC_Shim_MPSP_Wave + initBC_Shim_MPSP_Fall ) );
else
    initBC_Shim_MPSP = 0;
end

if ( gradMPSPSlewTime ~= 0 ) && (wz ~= 0)
    initBC_Grad_MPSP_Rise = gradSlewMPSPRise * gradMPSPSlewTime / 2;
    initBC_Grad_MPSP_Wave = ( gradSlewMPSPFallInt - gradSlewMPSPRiseInt );
    initBC_Grad_MPSP_Fall = gradSlewMPSPFall * gradMPSPSlewTime / 2;
    initBC_Grad_MPSP = Mxyz * ( -1 * ( ...
        initBC_Grad_MPSP_Rise + initBC_Grad_MPSP_Wave + initBC_Grad_MPSP_Fall ) );

else
    initBC_Grad_MPSP = 0;
end

% Calculate phase contribution from the future pulses and due to ΔΒ0
initBC_exp_Bzeff = exp( 1j * gyro * (...
    initBC_DB0 + initBC_Shim_Blip + initBC_Grad_Blip + initBC_Shim_MPSP + initBC_Grad_MPSP));
initBC_BC = ( BxySensCoil * bcOR );

% Integrate (using midpoint formula)
mInit = ( 1j * gyro * M0vec * dt ) .* (initBC_BC .* sum( ( initBC_exp_Bzeff), 2) );

%% Second Part of Split Definite Integral from Low-Flip Angle Equation
% There is nothing to integrate during the blip period, because there is no
% transverse pulse being played
% Multiphoton Excitation
% ΔB0 evolution
MP_DB0 = DB0Vec * ( tvecMPSP - tendMPSP );

% Integrate phase due to sinusoidal MPSP Fields from z coils
if ( shimMPSPSlewTime ~= 0 ) && (wz ~= 0)
    Shim_MPSP_int_waveforms = zeros( size( tMatMPSP ) );
    % Rise Integral
    Shim_MPSP_int_waveforms_Rise_Fall = -shimSlewMPSPFall * shimMPSPSlewTime / 2;
    Shim_MPSP_int_waveforms_Rise_Wave = -(shimSlewMPSPFallInt - shimSlewMPSPRiseInt);
    Shim_MPSP_int_waveforms_Rise_Rise = shimSlewMPSPRise/shimMPSPSlewTime .* (...
        tMatMPSP( :, Rise_Shim_i:Rise_Shim_f ).^2/2 - tendBlip*tMatMPSP( :, Rise_Shim_i:Rise_Shim_f )  -...
        ( ( tendBlip + shimMPSPSlewTime )^2/2 - tendBlip * ( tendBlip + shimMPSPSlewTime )  ) );
    Shim_MPSP_int_waveforms( :, Rise_Shim_i:Rise_Shim_f ) =...
         Shim_MPSP_int_waveforms_Rise_Fall +...
         Shim_MPSP_int_waveforms_Rise_Wave +...
         Shim_MPSP_int_waveforms_Rise_Rise;

    % Wave Integral
    Shim_MPSP_int_waveforms_Wave_Fall = -shimSlewMPSPFall * shimMPSPSlewTime / 2;
    Shim_MPSP_int_waveforms_Wave_Wave = (shimPhasorMag/wz) .*...
    sin( wz * ( tMatMPSP( :, Wave_Shim_i:Wave_Shim_f ) - tendBlip ) + shimPhasorPh ) - shimSlewMPSPFallInt;
    Shim_MPSP_int_waveforms( :, Wave_Shim_i:Wave_Shim_f ) =...
        Shim_MPSP_int_waveforms_Wave_Fall + Shim_MPSP_int_waveforms_Wave_Wave;

    % Fall Integral
    Shim_MPSP_int_waveforms_Fall_Fall = - shimSlewMPSPFall/shimMPSPSlewTime .*...
        ( tMatMPSP( :, Fall_Shim_i:Fall_Shim_f ).^2/2 - tendMPSP * tMatMPSP( :, Fall_Shim_i:Fall_Shim_f ) -...
        ( -tendMPSP^2/2 ) );
    Shim_MPSP_int_waveforms( :, Fall_Shim_i:Fall_Shim_f ) =...
        Shim_MPSP_int_waveforms_Fall_Fall;

    MP_Shim_MPSP = BzSensCoil * Shim_MPSP_int_waveforms;
else
    MP_Shim_MPSP = 0;
end

% Integrate phase due to sinusoidal MPSP Fields from gradients
if ( gradMPSPSlewTime ~= 0 ) && (wz ~= 0)
    Grad_MPSP_int_waveforms = zeros( size( tMatGradMPSP ) );
    % Rise Integral
    Grad_MPSP_int_waveforms_Rise_Fall = -gradSlewMPSPFall * gradMPSPSlewTime / 2;
    Grad_MPSP_int_waveforms_Rise_Wave = -(gradSlewMPSPFallInt - gradSlewMPSPRiseInt);
    Grad_MPSP_int_waveforms_Rise_Rise = gradSlewMPSPRise/gradMPSPSlewTime .* (...
        tMatGradMPSP( :, Rise_Grad_i:Rise_Grad_f ).^2/2 - tendBlip*tMatGradMPSP( :, Rise_Grad_i:Rise_Grad_f )...
        -  ( ( tendBlip + gradMPSPSlewTime )^2/2 - tendBlip * ( tendBlip + gradMPSPSlewTime )  ) );
    Grad_MPSP_int_waveforms( :, Rise_Grad_i:Rise_Grad_f ) =...
         Grad_MPSP_int_waveforms_Rise_Fall +...
         Grad_MPSP_int_waveforms_Rise_Wave +...
         Grad_MPSP_int_waveforms_Rise_Rise;

    % Wave Integral
    Grad_MPSP_int_waveforms_Wave_Fall = -gradSlewMPSPFall * gradMPSPSlewTime / 2;
    Grad_MPSP_int_waveforms_Wave_Wave = (gradPhasorMag/wz) .*...
    sin( wz * ( tMatGradMPSP( :, Wave_Grad_i:Wave_Grad_f ) - tendBlip ) + gradPhasorPh ) - gradSlewMPSPFallInt;
    Grad_MPSP_int_waveforms( :, Wave_Grad_i:Wave_Grad_f ) =...
        Grad_MPSP_int_waveforms_Wave_Fall + Grad_MPSP_int_waveforms_Wave_Wave;

    % Fall Integral
    Grad_MPSP_int_waveforms_Fall_Fall = - gradSlewMPSPFall/gradMPSPSlewTime .*...
        ( tMatGradMPSP( :, Fall_Grad_i:Fall_Grad_f ).^2/2 - tendMPSP * tMatGradMPSP( :, Fall_Grad_i:Fall_Grad_f ) -...
        ( -tendMPSP^2/2 ) );
    Grad_MPSP_int_waveforms( :, Fall_Grad_i:Fall_Grad_f ) =...
        Grad_MPSP_int_waveforms_Fall_Fall;

    MP_Grad_MPSP = Mxyz * Grad_MPSP_int_waveforms;
else
    MP_Grad_MPSP = 0;
end

% Calculate phase contribution from the MP pulse and due to ΔΒ0
MP_exp_Bzeff = exp( 1j * gyro * (MP_DB0 + MP_Shim_MPSP + MP_Grad_MPSP));
MP_BC = ( BxySensCoil * bcMP ) * exp( 1j * dwxy * ( tvecMPSP - tendBlip) );

mMP = (1j * gyro * M0vec * dt) .* sum( (MP_BC .* MP_exp_Bzeff) , 2);

%% Add Up Total Magnetization From the Split Integrals
mTot = mInit + mMP;

%% Check if There are NaN values, as this will ruin forward models
if any(isnan(mTot), "all")
    error('Returned NaN value in MP-pTx Forward Model');
end

end