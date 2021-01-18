function [chat,fhat,lambda,ss]=pc2(X,nfac)
% =========================================================================
% DESCRIPTION
% This function runs principal component analysis.
%
% -------------------------------------------------------------------------
% INPUTS
%           X      = dataset (one series per column)
%           nfac   = number of factors to be selected
%
% OUTPUTS
%           chat   = values of X predicted by the factors
%           fhat   = factors scaled by (1/sqrt(N)) where N is the number of
%                    series
%           lambda = factor loadings scaled by number of series
%           ss     = eigenvalues of X'*X 
%
% =========================================================================
% FUNCTION

% Number of series in X (i.e. number of columns)
N=size(X,2);

% Singular value decomposition: X'*X = U*S*V'
[U,S,~]=svd(X'*X);

% Factor loadings scaled by sqrt(N)
lambda=U(:,1:nfac)*sqrt(N);

% Factors scaled by 1/sqrt(N) (note that lambda is scaled by sqrt(N))
fhat=X*lambda/N;

% Estimate initial dataset X using the factors (note that U'=inv(U))
chat=fhat*lambda';

% Identify eigenvalues of X'*X
ss=diag(S);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


