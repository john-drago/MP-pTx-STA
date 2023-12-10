function MP = postProcessTotalEnergy( MP )
arguments
    MP
end

%% Get Structs
Waveform = MP.Waveform;
opt = MP.opt;

%% Get Values
RFphasor = Waveform.RFphasor;
tvec = Waveform.tvec;

%% Calculate Pulse Power
% BC Alone Pulse for Comparison
RFPhasor_BCAlone = opt.BCmag*ones(size(RFphasor));
RFPhasor_BCAlone(1) = 0;
RFPhasor_BCAlone(end) = 0;
opt.BC_PulsePower = calcPulsePower(...
   RFPhasor_BCAlone, tvec, opt.ZBC);

% Calculate MPpTx Global SAR by averaging the individual global SARs over
% the total time of the pulse
opt.mpptx_PulsePower = calcPulsePower(...
    RFphasor, tvec, opt.ZBC);

%% Assign values to structs
MP.opt = opt;

end

%% Helper Functions

% ----------------------------------------------------------------------- %
function  [PulsePower] = calcPulsePower( RFphasor, tvec, ZBC )
% Function will calculate the SAR specified by the pulse in the RFphasor
% vec at points specified by tvec

% Process Parameters
tend = tvec(end)-tvec(1);
dt = tvec(2) - tvec(1);

% Pulse Power
PulsePower = (dt/tend) * (1/ZBC) * (1/2) * sum(abs(RFphasor).^2, 'all');

end
% ----------------------------------------------------------------------- %