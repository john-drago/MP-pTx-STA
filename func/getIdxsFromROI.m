function [ijk, xyz] = getIdxsFromROI(roiFOV, FOV)
% Assumes a 3D input roiFOV. From the 3D input, the function will
% calculate both the ijk indices of the FOV points, and it will also
% calculate the xyz positions of the FOV points.
%
% Also assumes that there is a FOV struct that has X, Y, and Z definitions
% in the NDGRID format. [X, Y, Z] = ndgrid(xvec, yvec, zvec)

xyz = [...
    FOV.X(logical(roiFOV)),...
    FOV.Y(logical(roiFOV)),...
    FOV.Z(logical(roiFOV))];
if length(size(xyz))==3
    xyz = squeeze(xyz)';
end

[II, JJ, KK] = ndgrid(1:size(roiFOV,1), 1:size(roiFOV,2), 1:size(roiFOV,3));
ijk = [...
    II(logical(roiFOV)),...
    JJ(logical(roiFOV)),...
    KK(logical(roiFOV))];
if length(size(ijk))==3
    ijk = squeeze(ijk)';
end

end