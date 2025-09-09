function MP = runOpt(MP, optInit)
% This is a function that will control the optimization process with
% different flags for different optimization types.
% The MP struct needs to be passed as this is the central structure that
% contains information about the geometry and the fields of the MP problem.
%
% The optStruct is a way to pass optimization information that allows for
% problem specification before the optimization commences.
% Expected fields in optStruct:
%   - BzBound: max current (Amp-turns) to pass through shim coils during
%   MPSP
%   - BxyBCSPBound: max voltage amplitude for birdcage coil during BCSP
%   - BxyMPSPBound: max voltage amplitude for birdcage coil during MPSP
%   - gradMagScale: max gradient amplitude during MPSP period
%   - costfn: can pass a customized costfn to the optimization process. If
%   not specified, then will use the costfn at bottom of file
%   - fwdModName: specification of the fwd model to use in opt procedure
%   - optType: type of optimization request; either 'ga' or 'fmin'
%   - fminopt: optimization specifications for the fmin run
%   - gaopt: optimization specifications for the GA run
arguments
    MP; % MP struct that contains relevant information to run optimization process
    optInit; % struct of optimization inputs that will be used to control
    % the optimization process
end

%% Initialize structs to be passed through script
opt = MP.opt;
Val = MP.Val;

%% Set Up Bound Parameters
opt = getBoundsOpt( optInit, opt, Val );

%% Initialize Function Handles for Diff Fwd Models
[ opt, Val ] = getFnHandlesOpt( optInit, opt, Val );

%% Get Constraints, A, Aeq, lb, ub, etc.
[ opt, Val ] = getConstraintsOpt( optInit, opt, Val );

%% Create Optimization Opt Structs for GA and fmin
opt = getOptimizationStructsOpt( optInit, opt );

%% Opt Type Specific Actions and Run Opt
if strcmpi(optInit.optType,'fmin') || strcmpi(optInit.optType,'fmincon')

    if ~isfield(optInit, 'd0') || isempty(optInit.d0)
        %         opt.d0 = opt.lb + (opt.ub-opt.lb).*rand(length(opt.scVec),1);
        %         warning('Randomly initializing d0 vector of size:\t[%i,1]',length(opt.scVec));
        opt.d0 = zeros(length(opt.scVec),1);
        warning('Initializing d0 with zero vector of size:\t[%i,1]',length(opt.scVec));
    else
        opt.d0 = optInit.d0;
    end

    optTimeTic = tic;
    [dOptSc, opt] = runFmin( opt );
    opt.dOptSc = dOptSc;
    opt.optTime = toc( optTimeTic );

elseif strcmpi(optInit.optType,'ga')

    % Set State of Random Number Geneator if presented with one
    % Only applies to GA
    if ~isfield(optInit, 'rngstate') || isempty(optInit.rngstate)
        rng( 'shuffle' ); % randomly set seed based on the time
    else % Otherwise randomize the random number generator seed
        stream = RandStream.getGlobalStream;
        stream.State = optInit.rngstate.State;
    end

    optTimeTic = tic;
    [dOptSc, opt] = runGA( opt );
    opt.dOptSc = dOptSc;
    opt.optTime = toc( optTimeTic );

else
    error("Improper Optimization Type input.")
end

%% Post Process Opt to get parameters
opt.dOptSc = opt.dOptSc(:);
opt.dOpt = opt.scaleMat * opt.dOptSc;

%% Assign to MP struct
MP.opt = opt;
MP.Val = Val;

end