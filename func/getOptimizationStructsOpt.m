function opt = getOptimizationStructsOpt( optInit, opt )
% This function will process the optStruct to get the fminopt and/or gaopt
% specifications and pass them to the opt struct for optimization.

opt.optType = optInit.optType;

% Check to see which optimization is being run
if strcmpi(optInit.optType,'fmin') || strcmpi(optInit.optType,'fmincon')

    if ~isfield(optInit, 'fminopt')
        optInit.fminopt = initfMinOptStruct();
    end

    opt.fminopt = optInit.fminopt;

elseif strcmpi(optInit.optType,'ga')

    % Set Up Fmin To Run After GA is Complete Only if specified
    if isfield(optInit, 'fminopt') && ~isempty(optInit.fminopt)
        opt.fminopt = optInit.fminopt;
        optInit.gaopt.HybridFcn = {str2func(optInit.fminopt.SolverName), optInit.fminopt};
    end

    % Initialize GA opt struct
    if ~isfield(optInit, 'gaopt') || isempty(optInit.gaopt)
        optInit.gaopt = initGAOptStruct();
    end

    opt.inpBounds = repmat([-1;1], [1 length(opt.scVec)]);
    opt.inpBounds(1,1) = 0;

    optInit.gaopt.InitialPopulationRange = opt.inpBounds;

    opt.gaopt = optInit.gaopt;
else
    error("Improper Optimization Type input.")
end

end