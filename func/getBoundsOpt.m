function opt = getBoundsOpt( optInit, opt, Val )
% These parameters will form the bounds for the optimization process. We
% need to have distinct bounds for the birdcage pulse magnitude during the
% on-resonance subpulse and the multiphoton subpulse, becuase the length of
% each of the subpulses might be distinct.
% Will also establish bounds on the shim coils and over teh slew times if
% applicable.

FAMax = 90 * pi/180;
maxBxySens = max( abs(Val.BxySensCoil), [], "all" );
% maxEfficiencyMultiphoton = 0.582; % max percentage of on-resonance excitation
% % that can be achieved with multiphoton pulse

% Current Bound on Shim Amplifier
if ~isfield(optInit, 'BzBound')
    BzBound = 50;
else
    BzBound = optInit.BzBound;
end

% Current Bound on Blip Shim
if ~isfield(optInit, 'shimBlipBound')
    shimBlipBound = 15;
else
    shimBlipBound = optInit.shimBlipBound;
end

% Voltage Bound on BC during birdcage subpulse
if ~isfield(optInit, 'BxyBCSPBound') % Maximum voltage across BC coil
    BxyBCSPBound = FAMax/( opt.gyro * opt.tBCSP * maxBxySens );
else
    BxyBCSPBound = optInit.BxyBCSPBound;
end

% Voltage Bound on BC during multiphoton subpulse
if ~isfield(optInit, 'BxyMPSPBound') % Maximum voltage across BC coil
    BxyMPSPBound = FAMax/( opt.gyro * opt.tMPSP * maxBxySens );
else
    BxyMPSPBound = optInit.BxyMPSPBound;
end

% Gradient Magnitude Bound
% Bound due to user input
if ~isfield(optInit, 'gradMagScale')
    gradMagScaleExplicit = 25e-3;
else
    gradMagScaleExplicit = optInit.gradMagScale;
end

% Bound on Grad Magnitude Blip
if ~isfield(optInit, 'gradBlipBound')
    gradBlipBound = 0.005;
else
    gradBlipBound = optInit.gradBlipBound;
end

% Bound due to shim slew rate maximum
if ~isfield(optInit, 'shimSlewRateLimit')
    opt.shimSlewRateLimit = 3e6; % units: A/s
else
    opt.shimSlewRateLimit = optInit.shimSlewRateLimit;
end
% Bound due to grad slew rate maximum
if ~isfield(optInit, 'gradSlewRateLimit')
    opt.gradSlewRateLimit = 200; % units: T/(m*s)
else
    opt.gradSlewRateLimit = optInit.gradSlewRateLimit;
end
gradMagScaleSlew = opt.gradSlewRateLimit / ( 2*pi*opt.fz );

opt.shimBlipBound = shimBlipBound;
opt.BzBound = BzBound;
opt.BxyBCSPBound = BxyBCSPBound;
opt.BxyMPSPBound = BxyMPSPBound;
opt.gradBlipBound = gradBlipBound;
opt.gradMagScale = min( gradMagScaleExplicit, gradMagScaleSlew);

opt.scBz = opt.BzBound/sqrt(2);
opt.scBxyBCSP = opt.BxyBCSPBound;
opt.scBxyMPSP = opt.BxyMPSPBound/sqrt(2);
opt.scGrad = opt.gradMagScale/sqrt(2);
end