function MP = postProcessWaveform( MP, dt )
arguments
    MP
    dt = 1e-7; % default spacing of points
end
% Function that will generate waveforms can be used for Bloch Simulation at
% the Larmor frequency or other post-processing.

%% Get Structs
opt = MP.opt;

%% Create Waveforms
if contains( lower(opt.fwdModEvalName), "slew" )
    Waveform = postProcessWaveform_Slew( opt, dt );
else
    error( "Unknown fwdModEval type." )
end

%% Assign struct to MP
MP.Waveform = Waveform;

end