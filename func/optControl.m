function MP = optControl(...
    optInit, inpSt, bs, b1p, db0)
% This function will initialize the optimization process with
% MPpTxOptStruct and then will eventually call runOpt to run the
% optimization process.

%% Define Constants That Will be Used In Optimization Procedure
if isfield(inpSt, 'FAtargDeg')
    inpSt.FAtarg = inpSt.FAtargDeg * pi/180;
end

% Set interpolation dimensions if not already set
if ~(...
        isfield(inpSt, 'dxinterp') &&...
        isfield(inpSt, 'dyinterp') &&...
        isfield(inpSt, 'dzinterp'))
    inpSt.dxinterp = 0.010; % spacing along x-direction (R->L), left has higher values
    inpSt.dyinterp = 0.010; % spacing along y-direction (AP)
    inpSt.dzinterp = 0.010; % spacing along z-direction (SI)
end

%% Opt Struct Creation
MP = MPpTxOptStruct( inpSt, bs, b1p, db0 );

%% Run Optimization
MP = runOpt( MP, optInit );

%% Post Processing and Calculate Metrics
% Post Process Results
MP = MP.opt.postprocfnHandle( MP );

end