function Mxyvec = calcHPMag(B1Mag, tPulse, Struct)
% Function that will efficiently calculate the transverse magnetization
% (complex number) from an input B1Mag using the BxySensCoil Vector

if isfield(Struct, 'DB0Vec')
    BzVec = Struct.DB0Vec; % Field during hard pulse excitation in the rotating frame
else
    BzVec = zeros(size(Struct.BxySensCoil));
end

M0xyz = [zeros(size(Struct.M0vec)), zeros(size(Struct.M0vec)), Struct.M0vec]';
Bxyz = [B1Mag*real(Struct.BxySensCoil), B1Mag*imag(Struct.BxySensCoil), BzVec]';
magBxyz = vecnorm(Bxyz, 2, 1);
uBxyz = Bxyz./magBxyz;
th = -Struct.gyro * tPulse * magBxyz;

crs_uB_M0 = cross(uBxyz, M0xyz, 1);
dot_uB_M0 = dot(uBxyz, M0xyz, 1);

Mxyz = (M0xyz.*cos(th) + crs_uB_M0.*sin(th) + (1-cos(th)).*dot_uB_M0.*uBxyz)';

Mxyvec = Mxyz(:,1) + 1j*Mxyz(:,2);

if any(isnan(Mxyvec))
    error('Returned NaN value in MP-pTx Forward Model');
end

end