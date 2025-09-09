function ShimVec = generateShimVecFrom3D(ShimSens3D, roiFOV, FOVstruct)
% Function to generate vector of Shim Sensitivities From a 3D Vector
% Sensitivity Representation.
arguments
    ShimSens3D % Sensitivity profiles for each coil:
    % Dims: num coils x X dim x Y dim x Z dim x component direction
    roiFOV % ROI FOV logical struct
    FOVstruct % struct that has X Y Z arrays
end

%% Generate Indexes
[Mijk, ~] = getIdxsFromROI(roiFOV, FOVstruct);

%% Initialize and Generate Shim Vec
numPtsFOV = size(Mijk,1);
numBzCoils = size(ShimSens3D,1);
ShimVec = zeros(numPtsFOV, numBzCoils);

for cc = 1:numBzCoils
    % Extract element corresponding to coil number and third component
    % (z-directed portion of the field)
    bzind = sub2ind(size(ShimSens3D),...
        repmat(cc,[numPtsFOV, 1]) , Mijk(:,1), Mijk(:,2), Mijk(:,3) );
    ShimVec(:,cc) = ShimSens3D(bzind);
end

end