function [M] = blochSimHPShimODE( simSt, roiFOV, tol )
% Function that uses the MATLAB ODE integrator to simulate
% Bloch-equation governed magetization evolution for a "multiphoton"
% excitation.
%
% We assume that there are multiple possible coils with their own
% sensitivity profile for the xy-directed fields.
%
% For the transverse fields, we need a complex number that describes the
% amplitude and the phase of the current/voltage that is applied to produce
% transverse field. This is the phasor notation for the pulse profile that
% will be applied at the offset frequency wxy (although computations are
% performed in the Larmor rotating frame)
%
% dwxy: The offset frequency of the original B1xy pulse.
% Defined as dwxy = w0 - wxy. This corresponds to the offset frequency
% in the rotating frame.
% EXAMPLE: If dwxy = 2 * pi * 10 kHz, then that means that the wxy
% is 10 kHz under resonant frequency. This corresponds to a bessel
% function order of -1
arguments
    simSt
    roiFOV
    tol = 1e-4;
end

%% Define constants
gyro = 267.5e6; % rad/(T * sec) gyromagnetic ratio in terms of radians

%% Define the FOV domain
[ simSt.X, simSt.Y, simSt.Z ] = ndgrid( simSt.x, simSt.y, simSt.z );
domSize = size( simSt.X );

%% Get Fields for simulation
Grad = simSt.Grad;
RF = simSt.RF;
Shim = simSt.Shim;
tvec = simSt.tvec;
BzSens = simSt.BzSens;
BxySens = simSt.BxySens;
DB0 = simSt.DB0;
if isfield(simSt, 'M0')
    M0 = simSt.M0;
else
    M0 = [];
end

%% Check sizes of simulation parameters

% Manipulate Grad dimensions
if (size(Grad,2) ~= length(tvec))
    if (size(Grad,2) == 1) && (size(Grad,1) == 3)
        Grad = repmat(reshape(Grad, [3 1]), [1, length(tvec)]);
    else
        error('Grad must have the correct number of points corresponding to t vec')
    end
end

% Manipulate BzSens dimensions
if (length(BzSens) == 1)
    if BzSens == 1
        BzSens = cat(4, zeros([1, domSize]), zeros([1, domSize]), ones([1, domSize]));
    elseif BzSens == 0
        BzSens = cat(4, zeros([1, domSize]), zeros([1, domSize]), zeros([1, domSize]));
    else
        error('BzSens must have the correct spatial dimensions')
    end
elseif (length(size(BzSens)) == 4)
    if all( size( BzSens, [1 2 3] ) == domSize )
        BzSens = permute( BzSens, [4 1 2 3]);
    elseif all( size( BzSens, [2 3 4] ) ~= domSize )
        error('BzSens must have the correct spatial dimensions')
    end
elseif (length(size(BzSens)) == 3)
    if all( size( BzSens ) == domSize )
        BzSens = reshape( BzSens, [1 domSize] );
    end
elseif isempty( BzSens )
    BzSens = cat(4, zeros([1, domSize]), zeros([1, domSize]), zeros([1, domSize]));
else
    error('BzSens must have the correct spatial dimensions')
end

% Manipulate Shim dimensions
if (size(Shim,1) == length(tvec))
        Shim = Shim.';
elseif length(Shim) == 1
    if Shim == 0
        Shim = zeros( 1, length(tvec) );
    end
elseif isempty( Shim )
    Shim = zeros( 1, length(tvec) );
elseif size(Shim, 2) == 1
    Shim = repmat(reshape(Shim, [size(Shim, 2) 1]), [1 length(tvec)]);
end

% Manipulate RF dimensions
if (size(RF,2) ~= length(tvec))
    if size(RF,2) == 1
        RF = repmat(reshape(RF, [size(RF, 2) 1]), [1 length(tvec)]);
    else
        error('RF must have the correct number of points corresponding to t vec')
    end
end

% Manipulate BxySens dimensions
if (length(BxySens) == 1)
    if BxySens == 1
        BxySens = cat(4, 3.178655533761007e-08*ones([1, domSize]), zeros([1, domSize]), zeros([1, domSize]));
    elseif BxySens == 0
        BxySens = cat(4, zeros([1, domSize]), zeros([1, domSize]), zeros([1, domSize]));
    else
        error('BxySens must have the correct spatial dimensions')
    end
elseif (length(size(BxySens)) == 4)
    if all( size( BxySens, [1 2 3] ) == domSize )
        BxySens = permute( BxySens, [4 1 2 3]);
    elseif all( size( BxySens, [2 3 4] ) ~= domSize )
        error('BxySens must have the correct spatial dimensions')
    end
elseif (length(size(BxySens)) == 3)
    if all( size( BxySens ) == domSize )
        BxySens = reshape( BxySens, [1 domSize] );
    end
elseif isempty( BxySens )
    BxySens = cat(4, zeros([1, domSize]), zeros([1, domSize]), zeros([1, domSize]));
else
    error('BxySens must have the correct spatial dimensions')
end

% Manipulate M0 dimensions
if isempty(M0)
    M0 = repmat(reshape([0;0;1], [1, 1, 1, 3]), domSize);
elseif length(size(M0))==2
    if all(size(M0)==[3,1]) || all(size(M0)==[1,3])
        M0 = repmat(reshape(M0, [1, 1, 1, 3]), domSize);
    elseif M0 == 1
        M0 = repmat(reshape([0;0;1], [1, 1, 1, 3]), domSize);
    end
elseif all((size(M0,[1 2 3]) == domSize))
    M0 = M0; %#ok
else
    error('M0 must have the correct spatial dimensions')
end

% Manipulate DB0 dimensions
if isempty(DB0)
    DB0 = zeros(domSize);
else
    if (length(DB0) == 1) && (DB0 == 0)
        DB0 = zeros(domSize);
    elseif any((size(roiFOV,[1 2 3]) ~= domSize))
        error('ΔB0 must have the correct spatial dimensions')
    end
end

% Manipulate roiFOV dimensions
if (length(roiFOV) == 1)
    if roiFOV == 1
        roiFOV = ones(domSize);
    else
        error('roiFOV must have the correct spatial dimensions')
    end
elseif length(size(roiFOV)) == 3
    if any((size(roiFOV,[1 2 3]) ~= domSize))
        error('roiFOV must have the correct spatial dimensions')
    end
else
    error('roiFOV must have the correct spatial dimensions')
end

%% Start the Data Processing for the Simulation Loop

[ijk, xyz] = getIdxsFromROI(roiFOV, simSt);

numPtsFOV = size(ijk,1);
numBzCoils = size(BzSens,1);
numBxyCoils = size(RF,1);

BzSensCoilx = zeros(numPtsFOV, numBzCoils);
BzSensCoily = zeros(numPtsFOV, numBzCoils);
BzSensCoilz = zeros(numPtsFOV, numBzCoils);
for cc = 1:size(BzSens,1)
    bzind = sub2ind( size(BzSens), repmat(cc, [numPtsFOV, 1]) , ijk(:,1), ijk(:,2), ijk(:,3) );
    BzSensCoilz(:,cc) = BzSens(bzind);
end

BxySensCoil = zeros(numPtsFOV, numBxyCoils);
for bb = 1:numBxyCoils
    bxyind = sub2ind(size(BxySens), repmat(bb,[numPtsFOV, 1]), ijk(:,1), ijk(:,2), ijk(:,3));
    BxySensCoil(:,bb) = BxySens(bxyind);
end

db0ind = sub2ind(size(DB0), ijk(:,1), ijk(:,2), ijk(:,3));
DB0Vec = DB0(db0ind);

M0xidxs = sub2ind(size(M0),  ijk(:,1), ijk(:,2), ijk(:,3), repmat(1, [numPtsFOV,1 ])); %#ok
M0yidxs = sub2ind(size(M0),  ijk(:,1), ijk(:,2), ijk(:,3), repmat(2, [numPtsFOV,1 ]));
M0zidxs = sub2ind(size(M0),  ijk(:,1), ijk(:,2), ijk(:,3), repmat(3, [numPtsFOV,1 ]));

M0xyzstack = zeros(3*size(M0xidxs,1),1);
M0xyzstack(1:3:end) = M0(M0xidxs);
M0xyzstack(2:3:end) = M0(M0yidxs);
M0xyzstack(3:3:end) = M0(M0zidxs);

dMdtSt = struct;
dMdtSt.RF = RF;
dMdtSt.Grad = Grad;
dMdtSt.gyro = gyro;
dMdtSt.tvec = tvec;
dMdtSt.xyz = xyz;
dMdtSt.M0xyzstack = M0xyzstack;
dMdtSt.Shim = Shim;
dMdtSt.BxySensCoil = BxySensCoil;
dMdtSt.BzSensCoilx = BzSensCoilx;
dMdtSt.BzSensCoily = BzSensCoily;
dMdtSt.BzSensCoilz = BzSensCoilz;
dMdtSt.DB0Vec = DB0Vec;

tend = tvec(end);

%% Sim Loop
options = odeset('RelTol', tol, 'AbsTol', tol);

%% Sim Loop
if tend == 0
    Msim = M0xyzstack;
else
    [~, Msim] = ode45(...
        @(t,M) dMdtMP(t,M,dMdtSt),...
        [0, tend/2, tend], dMdtSt.M0xyzstack, options);

    Msim = Msim(end,:).';
end

M = zeros( size(M0) );

M(M0xidxs) = Msim(1:3:end);
M(M0yidxs) = Msim(2:3:end);
M(M0zidxs) = Msim(3:3:end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function dMdt = dMdtMP(t, Mt, dMdtSt)
% in the rotating frame at Larmor frequency

% This is how you would calculate the fields from the B1z coils in the
% rotating frame. As there is a massive difference between the Larmor
% Frequency at 7 T and the frequency of our z-directed field, this will
% take forever to compute.

% Z Fields
Shim = interp1( dMdtSt.tvec, dMdtSt.Shim.', t ).';
BzShim = dMdtSt.BzSensCoilz * ( Shim );
Grad = interp1( dMdtSt.tvec, dMdtSt.Grad.', t ).';
BzGrad = dMdtSt.xyz * Grad;
DB0 = dMdtSt.DB0Vec;

% XY Fields
RF = interp1( dMdtSt.tvec, dMdtSt.RF.', t).';
BxyRF = dMdtSt.BxySensCoil * RF;

Bt = [...
    real(BxyRF),...
    imag(BxyRF),...
    (BzGrad + BzShim + DB0)].';

Mt = reshape(Mt, [3, size(Bt,2)]);

dMdt = dMdtSt.gyro * (cross(Mt, Bt));

dMdt = reshape(dMdt, [3*size(dMdt,2),1]);

if any(isnan(dMdt))
    error('Returned NaN value in Bloch Sim');
end
end
