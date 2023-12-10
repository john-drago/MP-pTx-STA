function fminopt = initfMinOptStruct(...
    MaxIterations, MaxFuncEval, Display, UseParallel, Algorithm, FDStepSize, funcName,...
    printOutput )
% Function to initialize the options for the fmin run so that we don't have
% to explictly define them in each script.
arguments
    MaxIterations = 100
    MaxFuncEval = inf
    Display = 'iter'
    UseParallel = true
    Algorithm = 'sqp'
    FDStepSize = 1e-7;
    funcName = 'fmincon'
    printOutput = true
end

fminopt = optimoptions(funcName);
fminopt.Algorithm = Algorithm;
fminopt.Display = Display;
fminopt.StepTolerance = 1e-6;
fminopt.OptimalityTolerance = 1e-5;
fminopt.FunctionTolerance = 1e-5; % this does not matter for the SQP algorithm
fminopt.FiniteDifferenceStepSize = FDStepSize;
fminopt.MaxFunctionEvaluations = MaxFuncEval;
fminopt.MaxIterations = MaxIterations;
fminopt.UseParallel = UseParallel;

if printOutput
    fprintf('\n')
    fprintf('------------ fmin Options ------------')
    fprintf('\n')
    fprintf('fmin Function:\t\t%s\n', string(fminopt.SolverName))
    fprintf('fmin Max Iter:\t\t%i\n', MaxIterations)
    fprintf('fmin Max Func Eval:\t%i\n', MaxFuncEval)
    fprintf('fmin Algorithm:\t\t%s\n', string(Algorithm))
    fprintf('fmin FD Step Size:\t%e\n', FDStepSize)
    fprintf('fmin Use Parallel:\t%s\n', string(UseParallel))
    fprintf('fmin Display:\t\t%s\n', string(Display))
    fprintf('--------------------------------------')
    fprintf('\n')
    fprintf('\n')
end
end