function cost = MPpTxCost(dIter, evalStruct)
% Default cost function for the MPpTx optimization. This cost function will
% compute the NRMSE of the resultant magnetization distribution from the 

dIter = dIter(:); % make the design vector a column vector
Mtot = evalStruct.evalfnHandle(dIter, evalStruct); % get the resultant magnetization profile 
                % with the evalfn handle that has been passed

% Calculate the NRMSE and call it the "cost"
cost = norm( abs( Mtot )-abs( evalStruct.MTarg_vec ), 2)...
    / norm( abs(evalStruct.MTarg_vec), 2 );
end