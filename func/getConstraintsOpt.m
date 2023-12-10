function [ opt, Val ] = getConstraintsOpt( optStruct, opt, Val )
% Function will  create the equality and inequality constraints, and upper
% and lower bounds for the optimization procedure.
%
% Additionally, the file will create the scaleVec and scaleMat that will
% put all of the optimization variables on a similar scale.

% Define Equality and Inequality Constraints
opt.A = [];
opt.b = [];
opt.Aeq = [];
opt.beq = [];
opt.nonlcon = [];

% Specify maximum shim current allowed and maximum grad amplitude
maxShimBlip = min( opt.shimBlipBound, opt.BzBound ); % in A
maxGradBlip = min( opt.gradBlipBound, opt.gradMagScale ); % in T/m

if strcmpi(optStruct.fwdModName, 'Blip')

    % Make scVec
    opt.scVec = [opt.scBxyBCSP, opt.scBz*ones(1, 2*opt.numZCoils),...
        opt.scBxyMPSP*ones(1,2), opt.scGrad*ones(1,6),...
        maxShimBlip*ones(1, opt.numZCoils),...
        maxGradBlip*ones(1, 3)];
else
    error( 'Unknowwn forward model' )
end

% Specify maximum shim current allowed and maximum grad amplitude
opt.maxShimBlip = maxShimBlip;
opt.maxGradBlip = maxGradBlip;

minSlewTime = 10e-6;

opt.shimBlipSlewTime = max( opt.maxShimBlip / opt.shimSlewRateLimit, minSlewTime );
opt.shimMPSPSlewTime = max( opt.BzBound / opt.shimSlewRateLimit, minSlewTime );
opt.gradMPSPSlewTime = max( opt.gradMagScale / opt.gradSlewRateLimit, minSlewTime );

Val.shimBlipSlewTime = opt.shimBlipSlewTime;
Val.shimMPSPSlewTime = opt.shimMPSPSlewTime;
Val.gradMPSPSlewTime = opt.gradMPSPSlewTime;

if strcmpi( optStruct.fwdModEval, 'slew' )
    opt = calculateSlewPositions_Slew( opt );
    Val = calculateSlewPositions_Slew( Val );
else
    error( "Unknown fwdModEval type." )
end

% Make scVec a column vector
opt.scVec = opt.scVec(:);

% Perform actions based on Fwd Model Specific Actions
opt.numVars = length(opt.scVec); % define number of vars to optimize over
opt.scaleMat = sparse(diag(opt.scVec)); % make scaling into a diagonal matrix

% Define Bounds
opt.lb = -1*ones(size(opt.scVec,1), 1);
opt.ub = 1*ones(size(opt.scVec,1), 1);
opt.lb(1) = 0;
opt.ub(1) = 1;

end