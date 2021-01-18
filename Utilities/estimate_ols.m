

function [beta resid rsquare fitted] = estimate_ols(yobs,xobs)
 
yreg = yobs;
xreg = xobs;
 
 
beta  = mldivide(xreg'*xreg,xreg'*yreg);
fitted = xreg*beta;
resid = yreg - fitted;

rsquare = 1-sum(resid.^2)/sum((yreg-mean(yreg)).^2);

end