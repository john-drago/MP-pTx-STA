function Vrot = calcRRF(V, k, th)
% Assumes V is a 4D vector, where the first three coordinates
% correspond to the position in X,Y,Z coordinate system. The last
% dimension is the vector corresponding to that position.
%
% Assume k is also a 4D vector, the last dimension is the normal
% vector axis rotation for the correspondning X,Y,Z position.
%
% Theta should be a 3D vector. The value corresponds to the
% right-hand defined rotation at that position.
%
%
% Rodrigues Rotation Formula (RHR) (assumes rotation of vector v about
% axis v by an angle (right-hand rule defined) theta
% v_rot = v*cos(theta) + (k x v)sin(theta)+ (1-cos(theta))(k \cdot v)k

% use vectorized operations as this should be faster
crs_kV = zeros(size(V));
crs_kV(:,:,:,1) = k(:,:,:,2).*V(:,:,:,3) - k(:,:,:,3).*V(:,:,:,2);
crs_kV(:,:,:,2) = k(:,:,:,3).*V(:,:,:,1) - k(:,:,:,1).*V(:,:,:,3);
crs_kV(:,:,:,3) = k(:,:,:,1).*V(:,:,:,2) - k(:,:,:,2).*V(:,:,:,1);

dot_kV = dot(k, V, 4);

Vrot = V.*cos(th) + crs_kV.*sin(th) + (1-cos(th)).*dot_kV.*k;

end