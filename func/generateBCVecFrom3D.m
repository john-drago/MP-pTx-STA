function BCVec = generateBCVecFrom3D(BCSens3D, roiFOV, FOVstruct)
% Function to generate vector of BC Sensitivities From a 3D Vector
% (complex) sensitivity representation.
arguments
    BCSens3D % Sensitivity profiles for the BC coil:
        % Dims: X dim x Y dim x Z dim (index a complex number)
    roiFOV % ROI FOV logical struct
    FOVstruct % struct that has X Y Z arrays
end

%% Generate Indexes
[Mijk, ~] = getIdxsFromROI(roiFOV, FOVstruct);

%% Initialize and Generate Shim Vec
bxyind = sub2ind(size(BCSens3D), Mijk(:,1), Mijk(:,2), Mijk(:,3));
BCVec = BCSens3D(bxyind);

end