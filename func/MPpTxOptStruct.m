function MP = MPpTxOptStruct(...
    inpSt, bs, b1p, db0)
% Function that creates the main struct object that will be used throughout
% the optimization and validation process. The struct carries all relevant
% information and will be saved following the completion of the
% optimization process.

%% Create Structs that will be used
opt = struct;
Val = struct;

%% Define Impedance for Power Calculations
ZBC = 50;
opt.ZBC = ZBC;
Val.ZBC = ZBC;

%% Process input struct and assign constants to the opt struct
B0 = 7;
gyro = 267.5e6; % gyromagnetic ratio, rad /(T * s)
opt.B0 = B0;
opt.gyro = gyro;
opt.w0 = gyro*B0;
opt.FAtarg = inpSt.FAtarg; % radians
opt.FAtargDeg = inpSt.FAtarg * 180/pi; % degrees
opt.dfxy = inpSt.dfxy;
opt.dwxy = 2*pi*inpSt.dfxy;
opt.wz = 2*pi*inpSt.fz;
opt.fz = inpSt.fz;

%% Spatially Determine opt struct
opt.x = b1p.x(1) : inpSt.dxinterp : b1p.x(end);
opt.y = b1p.y(1) : inpSt.dyinterp : b1p.y(end);
opt.z = b1p.z(1) : inpSt.dzinterp : b1p.z(end);
[opt.X, opt.Y, opt.Z] = ndgrid(opt.x, opt.y, opt.z);

maskInterpThresh = 0.25;

opt.roi_body = Interp3D(b1p.X, b1p.Y, b1p.Z,...
    double(b1p.roi_body), opt.X, opt.Y, opt.Z) > maskInterpThresh;
opt.roi_brain = Interp3D(b1p.X, b1p.Y, b1p.Z,...
    double(b1p.roi_brain), opt.X, opt.Y, opt.Z) > maskInterpThresh;

%% Get brain indices
[ ~, ~, KK ] = ndgrid( 1:length(b1p.x), 1:length(b1p.y), 1:length(b1p.z) );
b1p.zi = unique( KK( b1p.roi_brain ) );

%% Find z indexes of interest and make ROI
tol = eps(1e2);
opt.zi = find( (opt.z >= (b1p.z(b1p.zi(1)) - tol) ) & ( opt.z <= ( b1p.z(b1p.zi(end)) + tol ) ) );

opt.roi_brain_planes = logical(opt.roi_brain(:,:,opt.zi));
opt.roi_body_planes = logical(opt.roi_body(:,:,opt.zi));

% get idxs from ROI brain for opt struct
[opt.Mijk, opt.Mxyz] = getIdxsFromROI(opt.roi_brain, opt);

%% Calculate Sensitivities
opt.numZCoils = size(bs.bz, 1);
opt.bzSens = zeros( opt.numZCoils,...
    length(opt.x), length(opt.y), length(opt.z) );

for cc = 1:opt.numZCoils
    opt.bzSens( cc, :, :, : ) = Interp3D(...
        bs.X, bs.Y, bs.Z, squeeze( bs.bz(cc, :, :, :) ),...
        opt.X, opt.Y, opt.Z);
end

% assuming that there is only one transverse coil
opt.b1p = Interp3D(...
    b1p.X, b1p.Y, b1p.Z, b1p.b1p,...
    opt.X, opt.Y, opt.Z);

%% Assign Timing Lengths
%  Need to create a unified system to identify the lengths of the important
%  subpulses
% We will always assume that the order of the subpulses is the following:
% (1) birdcage subpulse
% (2) blip in between subpulses
% (3) multiphoton subpulse
opt.tORSP = inpSt.tORSP; % time of the birdcage subpulse
opt.tBlip = inpSt.tBlip; % time of the blip in between the birdcage subpulse
% and the multiphoton subpulse
opt.tMPSP = inpSt.tMPSP; % time of the multiphoton subpulse

if opt.fz ~= 0
    Tfz = 1/opt.fz;
    ptsPerPeriod = 25; % Need roughly 10 points per period to integrate, but 
    % this provides a safety factor
    opt.dt = Tfz/ptsPerPeriod;
else
    opt.dt = 1e-6;
end

% Get time vectors for ORSP
opt.tendORSP = opt.tORSP;
opt.tvecORSP = (opt.dt/2) : opt.dt : opt.tendORSP;
opt.tMatORSP = repmat(opt.tvecORSP, [opt.numZCoils, 1]);
opt.tMatGradORSP = repmat(opt.tvecORSP, [3, 1]);

% Get time vectors for Blip in between subpulses
opt.tendBlip = opt.tBlip + opt.tendORSP;
opt.dt_tBlip = opt.tBlip/2;
opt.tvecBlip = (opt.tendORSP + opt.dt_tBlip/2) : opt.dt_tBlip : opt.tendBlip;
% assuming that we are integrating triangle waves, so we need to do the
% midpoint rule with two points during this period.

% Get time vectors for MPSP
opt.tendMPSP = opt.tendBlip + opt.tMPSP;
opt.tvecMPSP = (opt.tendBlip + opt.dt/2) : opt.dt : (opt.tendMPSP);
opt.tMatMPSP = repmat(opt.tvecMPSP, [opt.numZCoils, 1]);
opt.tMatGradMPSP = repmat(opt.tvecMPSP, [3, 1]);

%% Add Shim Calculations to opt struct
opt.DB0 = Interp3D(db0.X, db0.Y, db0.Z, db0.db0, opt.X, opt.Y, opt.Z);
opt.DB0Vec = opt.DB0(opt.roi_brain);

%% Get variables ready for optimization so that mat-mul can be used
numPtsFOV = size(opt.Mijk, 1);
M0 = [0;0;1];

opt.BzSensCoil =...
    generateShimVecFrom3D(opt.bzSens, opt.roi_brain, opt);
opt.BxySensCoil =...
    generateBCVecFrom3D(opt.b1p, opt.roi_brain, opt);

opt.M0 = repmat(...
    reshape(M0, [1, 1, 1, 3]), size(opt.b1p) ) .* opt.roi_brain;

M0idxs = sub2ind(...
    size(opt.M0),...
    opt.Mijk(:,1), opt.Mijk(:,2), opt.Mijk(:,3), repmat(3, [numPtsFOV,1 ]));
opt.M0vec = opt.M0(M0idxs);

%% Create Validation Geometries To Be Used During Post-Processing
% We will validate using the ROI body mask
Val.x = b1p.x;
Val.y = b1p.y;
Val.z = b1p.z;

Val.X = b1p.X;
Val.Y = b1p.Y;
Val.Z = b1p.Z;

tol = eps(1e2);
Val.zi = find( (Val.z >= (b1p.z(b1p.zi(1)) - tol) ) & ( b1p.z <= ( b1p.z(b1p.zi(end)) + tol ) ) );

Val.roi_body = b1p.roi_body;
Val.roi_brain = b1p.roi_brain;

Val.roi_brain_planes = logical(Val.roi_brain(:,:,Val.zi));
Val.roi_body_planes = logical(Val.roi_body(:,:,Val.zi));

Val.numZCoils = opt.numZCoils;

Val.bzSens = zeros( Val.numZCoils,...
    length(Val.x), length(Val.y), length(Val.z) );
for cc = 1:Val.numZCoils
    Val.bzSens( cc, :, :, : ) = Interp3D(...
        bs.X, bs.Y, bs.Z, squeeze( bs.bz(cc, :, :, :) ),...
        Val.X, Val.Y, Val.Z);
end

Val.b1p = Interp3D(...
    b1p.X, b1p.Y, b1p.Z, b1p.b1p,...
    Val.X, Val.Y, Val.Z);

Val.M0 = double(...
    repmat(reshape([0;0;1], [1, 1, 1, 3]), size(Val.roi_body,1:3)) .* Val.roi_body);
[Val.Mijk, Val.Mxyz] = getIdxsFromROI(Val.roi_body, Val);

Val.BzSensCoil =...
    generateShimVecFrom3D(Val.bzSens, Val.roi_body, Val);
Val.BxySensCoil =...
    generateBCVecFrom3D(Val.b1p, Val.roi_body, Val);

M0validxs = sub2ind(size(Val.M0),...
    Val.Mijk(:,1), Val.Mijk(:,2), Val.Mijk(:,3), repmat(3, [size(Val.Mijk, 1),1 ]));
Val.M0vec = Val.M0(M0validxs);

Val.FAtarg = opt.FAtarg;
Val.dwxy = opt.dwxy;
Val.wz = opt.wz;
Val.numZCoils = opt.numZCoils;
Val.gyro = opt.gyro;

% Set timing parameters for the Val Struct
Val.dt = opt.dt;

Val.tORSP = opt.tORSP;
Val.tBlip = opt.tBlip;
Val.tMPSP = opt.tMPSP;

Val.tendORSP = opt.tendORSP;
Val.tvecORSP = opt.tvecORSP;
Val.tMatORSP = opt.tMatORSP;
Val.tMatGradORSP = opt.tMatGradORSP;

Val.tendBlip = opt.tendBlip;
Val.dt_tBlip = opt.dt_tBlip;
Val.tvecBlip = opt.tvecBlip;

Val.tendMPSP = opt.tendMPSP;
Val.tvecMPSP = opt.tvecMPSP;
Val.tMatMPSP = opt.tMatMPSP;
Val.tMatGradMPSP = opt.tMatGradMPSP;

% Add Shim Calculations to Val struct
Val.DB0 = Interp3D(db0.X, db0.Y, db0.Z, db0.db0, Val.X, Val.Y, Val.Z);
Val.DB0Vec = Val.DB0(Val.roi_body);

%% Calculate BC voltage needed for initial pulse
% Will first perform excitation using unit voltage, and then we can use
% linearity to derive what voltage is needed to get average flip angle in
% the FOV. We will calculate what voltage is needed to get average flip
% angle in the validation discretization.
tBCHP = Val.tendMPSP; % length of birdcage hardpulse (for comparison)
Val.tBCHP = tBCHP;
opt.tBCHP = tBCHP;

B1SensVal = cat(4,... % Make complex sensitivity into a vector valued function
    real(Val.b1p),...
    imag(Val.b1p),...
    Val.DB0); % Add dB0, which will be present in the rotating frame
B1SensMagVal = sqrt(B1SensVal(:,:,:,1).^2 + B1SensVal(:,:,:,2).^2 + B1SensVal(:,:,:,3).^2);
B1SensUnitVal = B1SensVal ./ B1SensMagVal;
B1SensUnitVal(isnan(B1SensUnitVal)) = 0;
thetaksVal = -Val.gyro * tBCHP * B1SensMagVal;
MBCunit_Val_3D = Val.roi_brain .* calcRRF( Val.M0, B1SensUnitVal, thetaksVal);
MBCunit_Val_xy3D = MBCunit_Val_3D(:,:,:,1) + 1j*MBCunit_Val_3D(:,:,:,2);
MBCunit_Val_vec = MBCunit_Val_xy3D( Val.roi_brain );

Val.BCmag = Val.FAtarg / mean(asin(abs(MBCunit_Val_vec)));
opt.BCmag = Val.BCmag;

%% Develop target magnetization and phase of final profile for optimization
targMag = sin( opt.FAtarg );
targPh = 0;

opt.MTarg_xy3D = (targMag .* exp(1j*targPh)) .* opt.roi_brain;
opt.MTarg_xy3Dplanes = opt.MTarg_xy3D(:,:,opt.zi);
opt.MTarg_vec = opt.MTarg_xy3D(opt.roi_brain);

Val.MTarg_xy3D = (targMag .* exp(1j*targPh)) .* Val.roi_brain;
Val.MTarg_xy3Dplanes = Val.MTarg_xy3D(:,:,Val.zi);
Val.MTarg_vec = Val.MTarg_xy3D(Val.roi_brain);

%% Assign Structs to MP
MP.opt = opt;
MP.Val = Val;
end