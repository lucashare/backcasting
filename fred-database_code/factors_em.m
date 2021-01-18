function [ehat,Fhat,lamhat,ve2,x2] = factors_em(x,kmax,jj,DEMEAN)
% =========================================================================
% DESCRIPTION
% This program estimates a set of factors for a given dataset using
% principal component analysis. The number of factors estimated is
% determined by an information criterion specified by the user. Missing
% values in the original dataset are handled using an iterative
% expectation-maximization (EM) algorithm.
%
% -------------------------------------------------------------------------
% INPUTS
%           x       = dataset (one series per column)
%           kmax    = an integer indicating the maximum number of factors
%                     to be estimated; if set to 99, the number of factors
%                     selected is forced to equal 8
%           jj      = an integer indicating the information criterion used 
%                     for selecting the number of factors; it can take on 
%                     the following values:
%                           1 (information criterion PC_p1)
%                           2 (information criterion PC_p2)
%                           3 (information criterion PC_p3)      
%           DEMEAN  = an integer indicating the type of transformation
%                     performed on each series in x before the factors are
%                     estimated; it can take on the following values:
%                           0 (no transformation)
%                           1 (demean only)
%                           2 (demean and standardize)
%                           3 (recursively demean and then standardize) 
%
% OUTPUTS
%           ehat    = difference between x and values of x predicted by
%                     the factors
%           Fhat    = set of factors
%           lamhat  = factor loadings
%           ve2     = eigenvalues of x3'*x3 (where x3 is the dataset x post
%                     transformation and with missing values filled in)
%           x2      = x with missing values replaced from the EM algorithm
%
% -------------------------------------------------------------------------
% SUBFUNCTIONS
%
% baing() - selects number of factors
%
% pc2() - runs principal component analysis
%
% minindc() - finds the index of the minimum value for each column of a
%       given matrix
%
% transform_data() - performs data transformation
%
% -------------------------------------------------------------------------
% BREAKDOWN OF THE FUNCTION
%
% Part 1: Check that inputs are specified correctly.
%
% Part 2: Setup.
%
% Part 3: Initialize the EM algorithm -- fill in missing values with
%         unconditional mean and estimate factors using the updated
%         dataset.
%
% Part 4: Perform the EM algorithm -- update missing values using factors,
%         construct a new set of factors from the updated dataset, and
%         repeat until the factor estimates do not change.
% 
% -------------------------------------------------------------------------
% NOTES
% Authors: Michael W. McCracken and Serena Ng
% Date: 9/5/2017
% Version: MATLAB 2014a
% Required Toolboxes: None
%
% Details for the three possible information criteria can be found in the
% paper "Determining the Number of Factors in Approximate Factor Models" by
% Bai and Ng (2002).
%
% The EM algorithm is essentially the one given in the paper "Macroeconomic
% Forecasting Using Diffusion Indexes" by Stock and Watson (2002). The
% algorithm is initialized by filling in missing values with the
% unconditional mean of the series, demeaning and standardizing the updated
% dataset, estimating factors from this demeaned and standardized dataset,
% and then using these factors to predict the dataset. The algorithm then
% proceeds as follows: update missing values using values predicted by the
% latest set of factors, demean and standardize the updated dataset,
% estimate a new set of factors using the demeaned and standardized updated
% dataset, and repeat the process until the factor estimates do not change.
%
% =========================================================================
% PART 1: CHECKS

% Check that x is not missing values for an entire row
if sum(sum(isnan(x),2)==size(x,2))>0
    error('Input x contains entire row of missing values.');
end

% Check that x is not missing values for an entire column
if sum(sum(isnan(x),1)==size(x,1))>0
    error('Input x contains entire column of missing values.');
end

% Check that kmax is an integer between 1 and the number of columns of x,
% or 99
if ~((kmax<=size(x,2) && kmax>=1 && floor(kmax)==kmax) || kmax==99)
    error('Input kmax is specified incorrectly.');
end

% Check that jj is one of 1, 2, 3
if jj~=1 && jj~=2 && jj~=3
    error('Input jj is specified incorrectly.');
end

% Check that DEMEAN is one of 0, 1, 2, 3
if DEMEAN ~= 0 && DEMEAN ~= 1 && DEMEAN ~= 2 && DEMEAN ~= 3
    error('Input DEMEAN is specified incorrectly.');
end

% =========================================================================
% PART 2: SETUP

% Maximum number of iterations for the EM algorithm
maxit=100;

% Number of observations per series in x (i.e. number of rows)
T=size(x,1);

% Number of series in x (i.e. number of columns)
N=size(x,2);

% Set error to arbitrarily high number
err=999;

% Set iteration counter to 0
it=0;

% Locate missing values in x
x1=isnan(x);

% =========================================================================
% PART 3: INITIALIZE EM ALGORITHM
% Fill in missing values for each series with the unconditional mean of
% that series. Demean and standardize the updated dataset. Estimate factors
% using the demeaned and standardized dataset, and use these factors to
% predict the original dataset.

% Get unconditional mean of the non-missing values of each series
mut=repmat(nanmean(x),T,1);

% Replace missing values with unconditional mean
x2=x;
x2(isnan(x))=mut(isnan(x));

% Demean and standardize data using subfunction transform_data()
%   x3  = transformed dataset
%   mut = matrix containing the values subtracted from x2 during the
%         transformation
%   sdt = matrix containing the values that x2 was divided by during the
%         transformation
[x3,mut,sdt]=transform_data(x2,DEMEAN);

% If input 'kmax' is not set to 99, use subfunction baing() to determine
% the number of factors to estimate. Otherwise, set number of factors equal
% to 8
if kmax ~=99
    [icstar,~,~,~]=baing(x3,kmax,jj);
else
    icstar=8;
end

% Run principal components on updated dataset using subfunction pc2()
%   chat   = values of x3 predicted by the factors
%   Fhat   = factors scaled by (1/sqrt(N)) where N is the number of series
%   lamhat = factor loadings scaled by number of series
%   ve2    = eigenvalues of x3'*x3 
[chat,Fhat,lamhat,ve2]  = pc2(x3,icstar);

% Save predicted series values
chat0=chat;

% =========================================================================
% PART 4: PERFORM EM ALGORITHM
% Update missing values using values predicted by the latest set of
% factors. Demean and standardize the updated dataset. Estimate a new set
% of factors using the updated dataset. Repeat the process until the factor
% estimates do not change.

% Run while error is large and have yet to exceed maximum number of
% iterations
while err> 0.000001 && it <maxit
    
    % ---------------------------------------------------------------------
    % INCREASE ITERATION COUNTER
    
    % Increase iteration counter by 1
    it=it+1;
    
    % Display iteration counter, error, and number of factors
    fprintf('Iteration %d: obj %10f IC %d \n',it,err,icstar);

    % ---------------------------------------------------------------------
    % UPDATE MISSING VALUES
    
    % Replace missing observations with latest values predicted by the
    % factors (after undoing any transformation)
    for t=1:T;
        for j=1:N;
            if x1(t,j)==1
                x2(t,j)=chat(t,j)*sdt(t,j)+mut(t,j);    
            else
                x2(t,j)=x(t,j);
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % ESTIMATE FACTORS
    
    % Demean/standardize new dataset and recalculate mut and sdt using
    % subfunction transform_data()
    %   x3  = transformed dataset
    %   mut = matrix containing the values subtracted from x2 during the
    %         transformation
    %   sdt = matrix containing the values that x2 was divided by during 
    %         the transformation
    [x3,mut,sdt]=transform_data(x2,DEMEAN);
        
    % Determine number of factors to estimate for the new dataset using
    % subfunction baing() (or set to 8 if kmax equals 99)
    if kmax ~=99
        [icstar,~,~,~]=baing(x3,kmax,jj);
    else
        icstar=8;
    end

    % Run principal components on the new dataset using subfunction pc2()
    %   chat   = values of x3 predicted by the factors
    %   Fhat   = factors scaled by (1/sqrt(N)) where N is the number of 
    %            series
    %   lamhat = factor loadings scaled by number of series
    %   ve2    = eigenvalues of x3'*x3 
    [chat,Fhat,lamhat,ve2]  = pc2(x3,icstar);

    % ---------------------------------------------------------------------
    % CALCULATE NEW ERROR VALUE
    
    % Caclulate difference between the predicted values of the new dataset
    % and the predicted values of the previous dataset
    diff=chat-chat0;
    
    % The error value is equal to the sum of the squared differences
    % between chat and chat0 divided by the sum of the squared values of
    % chat0
    v1=diff(:);
    v2=chat0(:);
    err=(v1'*v1)/(v2'*v2);

    % Set chat0 equal to the current chat
    chat0=chat;
end

% Produce warning if maximum number of iterations is reached
if it==maxit
    warning('Maximum number of iterations reached in EM algorithm');
end

% -------------------------------------------------------------------------
% FINAL DIFFERNECE

% Calculate the difference between the initial dataset and the values 
% predicted by the final set of factors
ehat = x-chat.*sdt-mut;





