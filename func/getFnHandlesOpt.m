function [ opt, Val ] = getFnHandlesOpt( optInit, opt, Val )
% Function will process the optStruct to generate the function handles that
% will be passed throughuot the optimization process.

%% Eval Functions
evalfnNameBase = 'MPpTxEval_';
postprocfnNameBase = 'MPpTxPostProcess_';

if ~isfield(optInit, 'fwdModName') || isempty(optInit.fwdModName)
    optInit.fwdModName = 'Blip';
end

fwdModName = optInit.fwdModName;
evalfnName = strcat(evalfnNameBase, fwdModName);
postprocfnName = strcat(postprocfnNameBase, fwdModName);

if ~isfield( optInit, 'fwdModEval'  )
    optInit.fwdModEval = "slew";
end

fwdevalfnNameBase = "MPpTxEvalFwd_";
if strcmpi( optInit.fwdModEval, "slew" )
    fwdModEvalName = strcat( fwdevalfnNameBase, "Slew" );
else
    error( "Unknown fwdModEval type." )
end

opt.fwdModEvalName = optInit.fwdModEval;
opt.fwdModEvalHandle = str2func(fwdModEvalName);
opt.fwdModName = optInit.fwdModName;
opt.evalfnName = evalfnName;
opt.evalfnHandle = str2func(evalfnName);
opt.postprocfnName = postprocfnName;
opt.postprocfnHandle = str2func(postprocfnName);

Val.fwdModEvalName = opt.fwdModEvalName;
Val.fwdModEvalHandle = opt.fwdModEvalHandle;
Val.fwdModName = opt.fwdModName;
Val.evalfnName = opt.evalfnName;
Val.evalfnHandle = opt.evalfnHandle;

%% Cost Function
% Also create record of cost function
if ~isfield(optInit, 'costfn') || isempty(optInit.costfn)
    opt.costfn = @MPpTxCost;
else
    opt.costfn = optInit.costfn;
end

end