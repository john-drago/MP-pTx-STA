function [dOptSc, optStruct] = runFmin( optStruct )
% This function is used to run the fmin process within the optControl file.

%% Process anonymous functions
optStruct.costfnAnon = @(d) optStruct.costfn( optStruct.scaleMat*d(:), optStruct );
optStruct.costfnOpt = @(d) optStruct.costfnAnon(d(:));

optStruct.costfnAnon_str = func2str(optStruct.costfnAnon);
optStruct.costfnOpt_str = func2str(optStruct.costfnOpt);

%% Get Rid of Large Variables
if isfield(optStruct,"bzSens")
    optStruct = rmfield( optStruct, "bzSens" );
end
if isfield(optStruct,"M0")
    optStruct = rmfield( optStruct, "M0" );
end
if isfield(optStruct,"DB0")
    optStruct = rmfield( optStruct, "DB0" );
end
if isfield(optStruct,"b1p")
    optStruct = rmfield( optStruct, "b1p" );
end
if isfield(optStruct,"MTarg_xy3D")
    optStruct = rmfield( optStruct, "MTarg_xy3D" );
end
if isfield(optStruct,"MTarg_xy3Dplanes")
    optStruct = rmfield( optStruct, "MTarg_xy3Dplanes" );
end

%% Run Optimization
[dOptSc, optStruct.fval, optStruct.exitflag, optStruct.outputStruct, optStruct.lambda, optStruct.grad] = fmincon(...
    optStruct.costfnOpt, double(optStruct.d0),...
    optStruct.A, optStruct.b, optStruct.Aeq, optStruct.beq, optStruct.lb, optStruct.ub, optStruct.nonlcon,...
    optStruct.fminopt);

end