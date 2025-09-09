function MP = postProcessBlochSim( MP )
arguments
    MP
end

%% Get Structs
Waveform = MP.Waveform;
opt = MP.opt;
Val = MP.Val;

%% Time Length of Validation
simTimeTic = tic;

%% Simulate Results with Validation Resolution (defined in MPpTxOptStruct)
roiFOVBrain = Val.roi_brain;
roiFOVSim = Val.roi_body;

DB0 = MP.Val.DB0;

%% Get Waveforms for Pulse Simulations
tvec_BCalone = Waveform.tvec;
tvec_MPpTx = Waveform.tvec;

RF_BCalone = opt.BCmag * ones( size( Waveform.tvec ) );
RF_MPpTx = Waveform.RF;

Grad_BCalone = zeros( 3, 1 );
Grad_MPpTx = Waveform.Grad;

Shim_BCalone = 0;
Shim_MPpTx = Waveform.Shim;

bzSens = Val.bzSens;
b1p = Val.b1p;

x = Val.x;
y = Val.y;
z = Val.z;

%% Make the different sim structs
% BC Alone
sim_BCalone = struct;
sim_BCalone.tvec = tvec_BCalone;
sim_BCalone.RF = RF_BCalone;
sim_BCalone.Grad = Grad_BCalone;
sim_BCalone.Shim = Shim_BCalone;
sim_BCalone.BzSens = 0;
sim_BCalone.BxySens = b1p;
sim_BCalone.DB0 = DB0;
sim_BCalone.M0 = 1;
sim_BCalone.x = x;
sim_BCalone.y = y;
sim_BCalone.z = z;

% Pulse at end of blip period
sim_MPpTx = struct;
sim_MPpTx.tvec = tvec_MPpTx;
sim_MPpTx.RF = RF_MPpTx;
sim_MPpTx.Grad = Grad_MPpTx;
sim_MPpTx.Shim = Shim_MPpTx;
sim_MPpTx.BzSens = bzSens;
sim_MPpTx.BxySens = b1p;
sim_MPpTx.DB0 = DB0;
sim_MPpTx.M0 = 1;
sim_MPpTx.x = x;
sim_MPpTx.y = y;
sim_MPpTx.z = z;

%% Birdcage Alone (for comparison)
Val.MBC_3D = blochSimHPShimODE(...
    sim_BCalone, roiFOVSim);

clear sim_BCalone

Val.MBC_xy3D = Val.MBC_3D(:,:,:,1) + 1j*Val.MBC_3D(:,:,:,2);
Val.MBC_xy3Dplanes = squeeze(Val.MBC_xy3D(:,:,Val.zi));
Val.MBC_vec = Val.MBC_xy3D(roiFOVBrain);

%% Generate MPpTx Total by Doing Bloch Sim on Output of Initial BC
Val.Mmpptx_3D = blochSimHPShimODE(...
    sim_MPpTx, roiFOVSim);

clear sim_MPpTx

Val.Mmpptx_xy3D = Val.Mmpptx_3D(:,:,:,1) + 1j*Val.Mmpptx_3D(:,:,:,2);
Val.Mmpptx_xy3Dplanes = squeeze(Val.Mmpptx_xy3D(:,:,Val.zi));
Val.Mmpptx_vec = Val.Mmpptx_xy3D(roiFOVBrain);

%% Finish Timing of Simulation
Val.simTime = toc(simTimeTic);

%% Add Structs Back to MP
MP.opt = opt;
MP.Val = Val;
MP.Waveform = Waveform;

end