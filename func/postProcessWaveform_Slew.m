function [ Waveform ] = postProcessWaveform_Slew( opt, dt )

%% Create Waveform
Waveform = struct;

%% Initialize Waveforms
tvec = 0 : dt : opt.tendMPSP;

Grad = zeros( 3, length(tvec) );
Shim = zeros( opt.numZCoils, length(tvec) );
RF = zeros( 1, length(tvec) );
Freq = zeros( 1, length(tvec) );
RFphasor = zeros( 1, length(tvec) );

%% Find indices for different parts of the waveform
tStORSP = 0;
tEndORSP = opt.tendORSP;

tStBlip = opt.tendORSP;
tEndBlip = opt.tendBlip;

tStMPSP = opt.tendBlip;
tEndMPSP = opt.tendMPSP;

tol = dt/10;
ORSP_i = find( tvec >= ( tStORSP - tol  ), 1, 'first' );
ORSP_f = find( tvec <= ( tEndORSP + tol ), 1, 'last' );

Blip_i = find( tvec >= ( tStBlip - tol  ), 1, 'first' );
Blip_f = find( tvec <= ( tEndBlip + tol ), 1, 'last' );

MPSP_i = find( tvec >= ( tStMPSP - tol  ), 1, 'first' );
MPSP_f = find( tvec <= ( tEndMPSP + tol ), 1, 'last' );

if Blip_i == Blip_f
    Blip_i = [];
    Blip_f = [];

    if ORSP_f >= MPSP_i
        ORSP_f = ORSP_f - 1;
    end
else
    if ORSP_f >= Blip_i
        Blip_i = Blip_i + 1;
    end
    if Blip_f >= MPSP_i
        Blip_f = Blip_f - 1;
    end
end

%% Create Waveforms
% ORSP waveforms
RF( ORSP_i:ORSP_f ) = opt.bcOR;
RFphasor( ORSP_i:ORSP_f ) = opt.bcOR;

% Blip waveforms
tBlip = opt.tBlip;
if ~isempty(Blip_i) && ~isempty(Blip_f)
    
    % Grad Blip
    Grad( :, Blip_i:Blip_f ) = opt.gradAmpBlip * ( 1 - abs(tvec( Blip_i:Blip_f ) - ( tStBlip + tBlip/2 ) ) / ( tBlip / 2 )  );
    
    % Shim Blip
    shimBlipSlewTime = opt.shimBlipSlewTime;
    Shim( :, Blip_i:Blip_f ) = opt.shimAmpBlip * ones( 1, (Blip_f - Blip_i + 1) );
    shimRiseIdx = find( tvec( 1:Blip_f ) < ( tEndORSP + shimBlipSlewTime ), 1, "last" );
    shimFallIdx = find( tvec( 1:Blip_f ) > ( tEndBlip - shimBlipSlewTime ), 1, "first" );
    Shim( :, Blip_i:shimRiseIdx) = ( opt.shimAmpBlip/shimBlipSlewTime ) * ( tvec( Blip_i:shimRiseIdx ) - tEndORSP );
    Shim( :, shimFallIdx:Blip_f) = -( opt.shimAmpBlip/shimBlipSlewTime ) * ( tvec( shimFallIdx:Blip_f ) - tEndBlip );
end

% Slew Adjust for MPSP Waveforms
shimMPSPSlewTime = opt.shimMPSPSlewTime;
gradMPSPSlewTime = opt.gradMPSPSlewTime;

tRiseGradIdx = find( tvec <= ( tStMPSP + gradMPSPSlewTime), 1, "last" );
tFallGradIdx = find( tvec >= ( tEndMPSP - gradMPSPSlewTime), 1, "first" );

tRiseShimIdx = find( tvec <= ( tStMPSP + shimMPSPSlewTime ), 1, "last" );
tFallShimIdx = find( tvec >= ( tEndMPSP - shimMPSPSlewTime), 1, "first" );

% Grad MPSP
if ( gradMPSPSlewTime ~= 0 )
    Grad( :, MPSP_i:MPSP_f ) = opt.gradPhasorMag .* cos( opt.wz * ( repmat( tvec( MPSP_i:MPSP_f ), [3 1])  - tStMPSP ) + opt.gradPhasorPh );
    Grad( :, MPSP_i:tRiseGradIdx ) =  ( ( opt.gradPhasorMag .* cos( opt.wz * (gradMPSPSlewTime) + opt.gradPhasorPh ) ) / gradMPSPSlewTime)...
        * ( tvec( MPSP_i:tRiseGradIdx ) - tStMPSP );
    Grad( :, tFallGradIdx:MPSP_f ) = -( ( opt.gradPhasorMag .* cos( opt.wz * (tEndMPSP - tStMPSP - gradMPSPSlewTime) + opt.gradPhasorPh ) ) / gradMPSPSlewTime) *...
        ( tvec( tFallGradIdx:MPSP_f ) - tEndMPSP);
else
    Grad( :, MPSP_i:MPSP_f ) = 0;
end

% Shim MPSP
if ( shimMPSPSlewTime ~= 0 )
    Shim( :, MPSP_i:MPSP_f ) = opt.shimPhasorMag .* cos( opt.wz * ( repmat( tvec( MPSP_i:MPSP_f ), [opt.numZCoils 1]) - tStMPSP ) + opt.shimPhasorPh );
    Shim( :, MPSP_i:tRiseShimIdx ) =  ( ( opt.shimPhasorMag .* cos( opt.wz * (shimMPSPSlewTime) + opt.shimPhasorPh ) ) / shimMPSPSlewTime)...
        * ( tvec( MPSP_i:tRiseShimIdx ) - tStMPSP );
    Shim( :, tFallShimIdx:MPSP_f ) = -( ( opt.shimPhasorMag .* cos( opt.wz * (tEndMPSP - tStMPSP - shimMPSPSlewTime) + opt.shimPhasorPh ) ) / shimMPSPSlewTime)...
        * ( tvec( tFallShimIdx:MPSP_f ) - tEndMPSP);
else
    Shim( :, MPSP_i:MPSP_f ) = 0;
end

RF( MPSP_i:MPSP_f ) = opt.bcMP * exp( 1j * opt.dwxy * ( tvec( MPSP_i:MPSP_f ) - tStMPSP ) );
Freq( MPSP_i:MPSP_f ) = opt.dfxy;
RFphasor( MPSP_i:MPSP_f ) = opt.bcMP;

%% Set RF back to 0 and beginning and end
RF( 1 ) = 0; 
RF( end ) = 0;
RFphasor( 1 ) = 0;
RFphasor( end ) = 0;
Freq( 1 ) = 0;
Freq( end ) = 0;

%% Assign values to struct
Waveform.ORSP_i = ORSP_i;
Waveform.ORSP_f = ORSP_f;
Waveform.Blip_i = Blip_i;
Waveform.Blip_f = Blip_f;
Waveform.MPSP_i = MPSP_i;
Waveform.MPSP_f = MPSP_f;
Waveform.RF = RF;
Waveform.Grad = Grad;
Waveform.Freq = Freq;
Waveform.RFphasor = RFphasor;
Waveform.Shim = Shim;
Waveform.tvec = tvec;
Waveform.dt = dt;
Waveform.dfxy = opt.dfxy;
Waveform.dwxy = opt.dwxy;
Waveform.fz = opt.fz;
Waveform.wz = opt.wz;

end