function gaopt = initGAOptStruct(...
    PopSize, MaxGens, Display, UseParallel, printOutput)
% Function to initialize the options for the GA run so that we don't have
% to explictly define them in each script.
arguments
    PopSize = 1000
    MaxGens = 20
    Display = 'iter'
    UseParallel = true
    printOutput = true
end

gaopt = optimoptions('ga');
gaopt.CrossoverFraction = 0.6; %  fraction of the population at the next generation, not including elite children, that the crossover function creates
gaopt.Display = Display;
gaopt.FitnessLimit = 0.05;
gaopt.FunctionTolerance = 1e-5;
gaopt.FitnessScalingFcn = 'fitscalingrank';
gaopt.MaxGenerations = MaxGens;
gaopt.MaxStallGenerations = 10; % number of iters without cost function decrease
gaopt.PopulationSize = PopSize;
gaopt.MutationFcn = 'mutationpower'; % default: 'mutationadaptfeasible'
gaopt.UseParallel = UseParallel;
gaopt.UseVectorized = false;

if printOutput
    fprintf('\n')
    fprintf('------------- GA Options -------------')
    fprintf('\n')
    fprintf('GA Pop Size:\t\t%i\n', PopSize)
    fprintf('GA Max Generations:\t%i\n', MaxGens)
    if iscell(gaopt.MutationFcn)
        if isstring(gaopt.MutationFcn{1}) || ischar(gaopt.MutationFcn{1})
            fprintf('GA Mutation Function:\t%s\n', string(gaopt.MutationFcn{1}))
        elseif isa(gaopt.MutationFcn{1}, 'function_handle')
            fprintf('GA Mutation Function:\t%s\n', string(func2str(gaopt.MutationFcn{1})))
        end
    elseif isstring(gaopt.MutationFcn) || ischar(gaopt.MutationFcn)
        fprintf('GA Mutation Function:\t%s\n', string(gaopt.MutationFcn))
    elseif isa(gaopt.MutationFcn, 'function_handle')
        fprintf('GA Mutation Function:\t%s\n', string(func2str(gaopt.MutationFcn)))
    elseif isempty(gaopt.MutationFcn)
        fprintf('GA Mutation Function:\tDefault Mutation Function\n')
    else
        error("Can't parse mutationFcn")
    end
    fprintf('GA Use Parallel:\t%s\n', string(UseParallel))
    fprintf('GA Display:\t\t%s\n', string(Display))
    fprintf('--------------------------------------')
    fprintf('\n')
    fprintf('\n')
end

end