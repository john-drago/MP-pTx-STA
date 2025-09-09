function MP = MPpTxPostProcess_Blip( MP, runFuncs )
% function that will postprocess the output of the optimization process and
% will perform bloch sim validation of the result. The results will be
% reported in the MP struct that is used to pass all of the information
arguments
    MP
    runFuncs = true;
end

%% Get Struct
opt = MP.opt;

%% Process Optimized Vector
% Get Opt Output
opt.bcOR = opt.dOpt(1);

realShimOpt = opt.dOpt(1 + (1:2:2*opt.numZCoils));
imagShimOpt = opt.dOpt(1 + (2:2:2*opt.numZCoils));
opt.shimPhasor = realShimOpt + 1j*imagShimOpt;
opt.shimPhasorMag = abs(opt.shimPhasor);
opt.shimPhasorPh = angle(opt.shimPhasor);

realbcMP = opt.dOpt(1+2*opt.numZCoils + 1);
imagbcMP = opt.dOpt(1+2*opt.numZCoils + 2);
opt.bcMP = realbcMP + 1j*imagbcMP;

opt.gradPhasor = opt.dOpt((1+2*opt.numZCoils+3):2:(1+2*opt.numZCoils+8)) + ...
    1j*opt.dOpt((1+2*opt.numZCoils+4):2:(1+2*opt.numZCoils+8));
opt.gradPhasorMag = abs(opt.gradPhasor);
opt.gradPhasorPh = angle(opt.gradPhasor);

opt.shimAmpBlip = opt.dOpt( (1+2*opt.numZCoils+9):1:(1+2*opt.numZCoils+9+opt.numZCoils-1) );
opt.gradAmpBlip = opt.dOpt( (1+3*opt.numZCoils+9):1:(1+3*opt.numZCoils+11) );

MP.opt = opt;

%% Run Post Process Functions
if runFuncs
    MP = postProcessControl( MP );
end

end
