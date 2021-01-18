function pos=minindc(x)
% =========================================================================
% DESCRIPTION
% This function finds the index of the minimum value for each column of a
% given matrix. The function assumes that the minimum value of each column
% occurs only once within that column. The function returns an error if
% this is not the case.
%
% -------------------------------------------------------------------------
% INPUT
%           x   = matrix 
%
% OUTPUT
%           pos = column vector with pos(i) containing the row number
%                 corresponding to the minimum value of x(:,i)
%
% =========================================================================
% FUNCTION

% Number of rows and columns of x
nrows=size(x,1);
ncols=size(x,2);

% Preallocate memory for output array
pos=zeros(ncols,1);

% Create column vector 1:nrows
seq=(1:nrows)';

% Find the index of the minimum value of each column in x
for i=1:ncols
    
    % Minimum value of column i
    min_i=min(x(:,i));
    
    % Column vector containing the row number corresponding to the minimum
    % value of x(:,i) in that row and zeros elsewhere
    colmin_i= seq.*((x(:,i)-min_i)==0);
    
    % Produce an error if the minimum value occurs more than once
    if sum(colmin_i>0)>1
        error('Minimum value occurs more than once.');
    end
    
    % Obtain the index of the minimum value by taking the sum of column
    % vector 'colmin_i'
    pos(i)=sum(colmin_i);
    
end


