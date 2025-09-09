function evalStruct = calculateSlewPositions_Slew( evalStruct )

%% Get fields
tendBlip = evalStruct.tendBlip;
tendMPSP = evalStruct.tendMPSP;
tvecMPSP = evalStruct.tvecMPSP;
shimMPSPSlewTime = evalStruct.shimMPSPSlewTime;
gradMPSPSlewTime = evalStruct.gradMPSPSlewTime;

%% Get the Idxs of Three Phases (Rise, Wave, Fall) in the MPSP
Rise_Shim_i = 1;
Rise_Shim_f = find( tvecMPSP <= ( tendBlip + shimMPSPSlewTime ), 1, "last" );
Fall_Shim_i = find( tvecMPSP >= ( tendMPSP - shimMPSPSlewTime ), 1, "first" );
Fall_Shim_f = length( tvecMPSP );
if isempty(Rise_Shim_f)
    Rise_Shim_i = [];
    Rise_Shim_f = [];
    Wave_Shim_i = 1;
else
    Wave_Shim_i = Rise_Shim_f + 1;
end
if isempty(Fall_Shim_i)
    Fall_Shim_i = [];
    Fall_Shim_f = [];
    Wave_Shim_f = length( tvecMPSP );
else
    Wave_Shim_f = Fall_Shim_i - 1;
end

Rise_Grad_i = 1;
Rise_Grad_f = find( tvecMPSP <= ( tendBlip + gradMPSPSlewTime ), 1, "last" );
Fall_Grad_i = find( tvecMPSP >= ( tendMPSP - gradMPSPSlewTime ), 1, "first" );
Fall_Grad_f = length( tvecMPSP );
if isempty(Rise_Grad_f)
    Rise_Grad_i = [];
    Rise_Grad_f = [];
    Wave_Grad_i = 1;
else
    Wave_Grad_i = Rise_Grad_f + 1;
end
if isempty(Fall_Grad_i)
    Fall_Grad_i = [];
    Fall_Grad_f = [];
    Wave_Grad_f = length( tvecMPSP );
else
    Wave_Grad_f = Fall_Grad_i - 1;
end

%% Assign to Struct
evalStruct.Rise_Shim_i = Rise_Shim_i;
evalStruct.Rise_Shim_f = Rise_Shim_f;
evalStruct.Wave_Shim_i = Wave_Shim_i;
evalStruct.Wave_Shim_f = Wave_Shim_f;
evalStruct.Fall_Shim_i = Fall_Shim_i;
evalStruct.Fall_Shim_f = Fall_Shim_f;

evalStruct.Rise_Grad_i = Rise_Grad_i;
evalStruct.Rise_Grad_f = Rise_Grad_f;
evalStruct.Wave_Grad_i = Wave_Grad_i;
evalStruct.Wave_Grad_f = Wave_Grad_f;
evalStruct.Fall_Grad_i = Fall_Grad_i;
evalStruct.Fall_Grad_f = Fall_Grad_f;

end