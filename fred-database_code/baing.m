function [ic1,chat,Fhat,eigval]=baing(X,kmax,jj)
% =========================================================================
% DESCRIPTION
% This function determines the number of factors to be selected for a given
% dataset using one of three information criteria specified by the user.
% The user also specifies the maximum number of factors to be selected.
%
% -------------------------------------------------------------------------
% INPUTS
%           X       = dataset (one series per column)
%           kmax    = an integer indicating the maximum number of factors
%                     to be estimated
%           jj      = an integer indicating the information criterion used 
%                     for selecting the number of factors; it can take on 
%                     the following values:
%                           1 (information criterion PC_p1)
%                           2 (information criterion PC_p2)
%                           3 (information criterion PC_p3)    
%
% OUTPUTS
%           ic1     = number of factors selected
%           chat    = values of X predicted by the factors
%           Fhat    = factors
%           eigval  = eivenvalues of X'*X (or X*X' if N>T)
%
% -------------------------------------------------------------------------
% SUBFUNCTIONS USED
%
% minindc() - finds the index of the minimum value for each column of a
%       given matrix
%
% -------------------------------------------------------------------------
% BREAKDOWN OF THE FUNCTION
%
% Part 1: Setup.
%
% Part 2: Calculate the overfitting penalty for each possible number of
%         factors to be selected (from 1 to kmax).
%
% Part 3: Select the number of factors that minimizes the specified
%         information criterion by utilizing the overfitting penalties
%         calculated in Part 2.
%
% Part 4: Save other output variables to be returned by the function (chat,
%         Fhat, and eigval). 
%
% =========================================================================
% PART 1: SETUP

% Number of observations per series (i.e. number of rows)
T=size(X,1);

% Number of series (i.e. number of columns)
N=size(X,2);

% Total number of observations
NT=N*T;

% Number of rows + columns
NT1=N+T;

% =========================================================================
% PART 2: OVERFITTING PENALTY
% Determine penalty for overfitting based on the selected information
% criterion. 

% Allocate memory for overfitting penalty
CT=zeros(1,kmax);

% Array containing possible number of factors that can be selected (1 to
% kmax)
ii=1:1:kmax;

% The smaller of N and T
GCT=min([N;T]);

% Calculate penalty based on criterion determined by jj. 
switch jj
    
    % Criterion PC_p1
    case 1
        CT(1,:)=log(NT/NT1)*ii*NT1/NT;
        
    % Criterion PC_p2
    case 2
        CT(1,:)=(NT1/NT)*log(min([N;T]))*ii;
        
    % Criterion PC_p3
    case 3
        CT(1,:)=ii*log(GCT)/GCT;
        
end

% =========================================================================
% PART 3: SELECT NUMBER OF FACTORS
% Perform principal component analysis on the dataset and select the number
% of factors that minimizes the specified information criterion.

% -------------------------------------------------------------------------
% RUN PRINCIPAL COMPONENT ANALYSIS

% Get components, loadings, and eigenvalues
if T<N 
    
    % Singular value decomposition
    [ev,eigval,~]=svd(X*X'); 
    
    % Components
    Fhat0=sqrt(T)*ev;
    
    % Loadings
    Lambda0=X'*Fhat0/T;
    
else
    
    % Singular value decomposition
    [ev,eigval,~]=svd(X'*X);
    
    % Loadings
    Lambda0=sqrt(N)*ev;
    
    % Components
    Fhat0=X*Lambda0/N;

end

% -------------------------------------------------------------------------
% SELECT NUMBER OF FACTORS 
    
% Preallocate memory
Sigma=zeros(1,kmax+1); % sum of squared residuals divided by NT
IC1=zeros(size(CT,1),kmax+1); % information criterion value

% Loop through all possibilites for the number of factors 
for i=kmax:-1:1

    % Identify factors as first i components
    Fhat=Fhat0(:,1:i);

    % Identify factor loadings as first i loadings
    lambda=Lambda0(:,1:i);

    % Predict X using i factors
    chat=Fhat*lambda';

    % Residuals from predicting X using the factors
    ehat=X-chat;

    % Sum of squared residuals divided by NT
    Sigma(i)=mean(sum(ehat.*ehat/T));

    % Value of the information criterion when using i factors
    IC1(:,i)=log(Sigma(i))+CT(:,i);
    
end

% Sum of squared residuals when using no factors to predict X (i.e.
% fitted values are set to 0)
Sigma(kmax+1)=mean(sum(X.*X/T));

% Value of the information criterion when using no factors
IC1(:,kmax+1)=log(Sigma(kmax+1));

% Number of factors that minimizes the information criterion
ic1=minindc(IC1')';

% Set ic1=0 if ic1>kmax (i.e. no factors are selected if the value of the
% information criterion is minimized when no factors are used)
ic1=ic1 .*(ic1 <= kmax);

% =========================================================================
% PART 4: SAVE OTHER OUTPUT

% Factors and loadings when number of factors set to kmax
Fhat=Fhat0(:,1:kmax); % factors
Lambda=Lambda0(:,1:kmax); % factor loadings

% Predict X using kmax factors
chat=Fhat*Lambda';

% Get the eivenvalues corresponding to X'*X (or X*X' if N>T)
eigval=diag(eigval);


