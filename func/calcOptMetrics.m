function MP = calcOptMetrics(MP)
arguments
    MP
end
% This function will calculate metrics of the optimzation process based on
% the geometry in the Val substruct (under the MP struct).

opt = MP.opt;
Val = MP.Val;

%% Use Bloch Sim Validation or Validation for the Optimization Metrics
Mmpptx_vec_calc = Val.Mmpptx_vec;
MBC_vec_calc = Val.MBC_vec;

%% Assign the target arrays
MTarg_vec_calc = Val.MTarg_vec(:);

%% Get number of points in the vector
numVox = size( MTarg_vec_calc, 1 );

%% Metrics Calculated Over Entire FOV
opt.mpptx_magNRMSE = norm(abs(Mmpptx_vec_calc) - abs(MTarg_vec_calc), 2)/norm(abs(MTarg_vec_calc), 2);
opt.mpptx_NRMSE = norm(Mmpptx_vec_calc - MTarg_vec_calc, 2)/norm(MTarg_vec_calc, 2);
opt.mpptx_magCoeffVar = std(abs(Mmpptx_vec_calc))/mean(abs(Mmpptx_vec_calc));
opt.mpptx_NMaxMin = (max(abs(Mmpptx_vec_calc))-min(abs(Mmpptx_vec_calc)))/mean(abs(Mmpptx_vec_calc));
opt.mpptx_MAE = norm(abs(Mmpptx_vec_calc) - abs(MTarg_vec_calc), 1) / numVox;
opt.mpptx_NMAE = ( 1 / numVox ) * norm(abs(Mmpptx_vec_calc) - abs(MTarg_vec_calc), 1)/norm(abs(MTarg_vec_calc), 1);
mpptx_FADeg = asin(abs(Mmpptx_vec_calc)) * 180/pi;
opt.mpptx_FAMean = mean(mpptx_FADeg);
opt.mpptx_FAStd = std(mpptx_FADeg);

opt.BC_magNRMSE = norm(abs(MBC_vec_calc) - abs(MTarg_vec_calc), 2)/norm(abs(MTarg_vec_calc), 2);
opt.BC_NRMSE = norm(MBC_vec_calc - MTarg_vec_calc, 2)/norm(MTarg_vec_calc, 2);
opt.BC_magCoeffVar = std(abs(MBC_vec_calc))/mean(abs(MBC_vec_calc));
opt.BC_NMaxMin = (max(abs(MBC_vec_calc))-min(abs(MBC_vec_calc)))/mean(abs(MBC_vec_calc));
opt.BC_MAE = norm(abs(MBC_vec_calc) - abs(MTarg_vec_calc), 1) / numVox;
opt.BC_NMAE = ( 1 / numVox ) * norm(abs(MBC_vec_calc) - abs(MTarg_vec_calc), 1)/norm(abs(MTarg_vec_calc), 1);
BC_FADeg = asin(abs(MBC_vec_calc)) * 180/pi;
opt.BC_FAMean = mean(BC_FADeg);
opt.BC_FAStd = std(BC_FADeg);

%% Save information to Structs
MP.opt = opt;

end