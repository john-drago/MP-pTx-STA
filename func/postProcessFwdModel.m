function MP = postProcessFwdModel(MP, evalfnHandle )
arguments
    MP
    evalfnHandle
end
% Compute the fwd model at validation resolution. To compare results
% between the forward model at the higher resolution and the bloch sim
% results

%% Get Structs
Val = MP.Val;
opt = MP.opt;

%% Set Parameters For Later Use
zi = Val.zi;

%% Generate MBC from Birdcage Only Pulse
Val.MBCfwd_fullVec = calcHPMag(Val.BCmag, Val.tBCHP, Val);
Val.MBCfwd_xy3D = MPpTxRegenFOV( Val.MBCfwd_fullVec, Val.roi_body );
Val.MBCfwd_xy3Dplanes = Val.MBCfwd_xy3D(:,:,zi);
Val.MBCfwd_vec = Val.MBCfwd_xy3D( Val.roi_brain );

%% Generate MPpTx from the Forward Model
[Val.Mmpptxfwd_fullVec] =...
    evalfnHandle(opt.dOpt, MP.Val);

Val.Mmpptxfwd_xy3D = MPpTxRegenFOV( Val.Mmpptxfwd_fullVec, Val.roi_body );
Val.Mmpptxfwd_xy3Dplanes = Val.Mmpptxfwd_xy3D(:,:,zi);
Val.Mmpptxfwd_vec = Val.Mmpptxfwd_xy3D( Val.roi_brain );

%% Add Structs to MP Struct
MP.opt = opt;
MP.Val = Val;

end