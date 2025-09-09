function MP = postProcessControl( MP )
arguments
    MP
end

%% Waveform Post Process
MP = postProcessWaveform( MP );

%% Bloch Sim Post Process
MP = postProcessBlochSim( MP );

%% Fwd Model Post Process
MP = postProcessFwdModel( MP, MP.opt.evalfnHandle );

%% Calculate Energy in BC Pulses
MP = postProcessTotalEnergy( MP );

%% Calc Opt Metrics
MP = calcOptMetrics( MP );

end