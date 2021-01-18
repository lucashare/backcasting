function [ts_filled, ts_factors, ts_resid] = backcast_ts(ts, n_factors, other_factors, max_iterations, tol0, myfloor)
% =========================================================================
% DESCRIPTION
          % Wrapper for backcast_data_general
          % This routine takes as input an unbalanced dataset with an arbitrary pattern of missing observations. For contiguously missing observations 
          % at the beginning or at the end of each series, the routine relies on an extension of the method of Stock and Watson as described in the
          % Guerrieri, L. and C. Harkrader 'What Drives Bank Performance,' which allows for use of external factors. Missing observations away from the 
          % begging or end sections of each series are filled in using cubic splines.
% -------------------------------------------------------------------------
% INPUTS
          % ts: array or timetable with series of different length.
          % n_factors: integer indicating number of factors to extract from the dataset. 
          % The dataset with missing observations needs to include at least 
          % as many series with non-missing observations at the beginning or 
          % at the end of the dataset as the number of factors to be extracted from the dataset.
          % other_factors: array or timetable of factors external to the first dataset to
          % be used for backcasts. If omitted, we just add a constant.
          % max_iterations: optional integer indicating maximum number of iterations before aborting.
          % The default value is 100,000.
          % tol0: optional parameter used to determine convergence, maximum 
          % absolute difference in forecast between iterations. The default
          % value is 0.001.
          % myfloor: optional theoretical lower bound for any observation to be
          % imputed --- if the imputed values fall below myfloor, myfloor
          % is used instead. The default value is -infinity.
% OUTPUTS
          % ts_filled: array or timetable of the same shape ts but with missing values filled in.
          % ts_factors: array or timetable with factors extracted from the time table ts.
          % ts_resid: array or timetable of residuals for each series in ts_filled 
          % not explained by external factors or additional factors extracted from ts.
          % NB: if ts is an array, ts_filled, ts_factors and ts_resid will
          % be returned as arrays. 
          
% -------------------------------------------------------------------------
% BREAKDOWN OF THE FUNCTION
% Part 1: Check that there is sufficient data to run the procedure.
% Part 2: Setup data for procedure
% Part 3: Perform the extended Stock and Watson (2002) procedure 
% -------------------------------------------------------------------------
% NOTES
% Authors: Luca Guerrieri & James Collin Harkrader
% Date: 1/6/2020
% Version: MATLAB 2018b, 2019b
%
% =========================================================================

  
%% Assign default variables if input variables are missing 
if ~exist('max_iterations', 'var')
  max_iterations = 1e5;
end

if ~exist('other_factors', 'var')
    other_factors = [ones(size(ts{:,:},1),1)];
else
    
end

if ~exist('tol0', 'var')
  tol0 = 1e-3;
end

if ~exist('myfloor','var')
    myfloor=-inf;
end
%% Preprocessing Data to call backcast_data_general()

% Raw Data in Matrix Format

if isa(ts,'timetable')
    data_mat = ts{:,:};
else
    data_mat = ts;
end

if isa(other_factors,'timetable')
    ts_range = timerange(ts.Properties.RowTimes(1),ts.Properties.RowTimes(end),'closed');
    other_factors = other_factors{ts_range,:};
end

% compile info on start and end of each series and missing obs
start_end_data_by_column = find_start_end_and_nans(data_mat);


% check if we have at least 10% of the columns with no missing values.
max_nobs = size(data_mat,1);

n_columns = size(data_mat,2);

% check that end point matches the maximum number of observations and that the start point is 1
select_full_columns = (start_end_data_by_column(2,:)==max_nobs) & (start_end_data_by_column(1,:) == 1)  ;

%
n_full_columns = sum(select_full_columns);

if n_full_columns<n_factors
    error('There are not enough columns without missing observations at the beginning or at the end for the number of factors selected')
end
    
% create the partition of the original data with full data
data_full_columns = data_mat(:,select_full_columns);

% now select the balanced columns 
latest_start = max(start_end_data_by_column(1,:));
earliest_end = min(start_end_data_by_column(2,:));
data_balanced_columns = data_mat(latest_start:earliest_end,:);

% fill in any data holes (missing data not at the begining and not at the end) with splines
 
for this_col = 1:n_full_columns
    data_full_columns(:,this_col) = cubic_spline_fill( data_full_columns(:,this_col) );    
end
 
for this_col = 1:n_columns
    data_balanced_columns(:,this_col) = cubic_spline_fill(data_balanced_columns(:,this_col));    
end


%% Extended Stock and Watson 2002 Procedure
[ts_filled, ts_factors, ts_resid]  = ...
    backcast_data_general(data_mat,...
                          data_balanced_columns,...
                          data_full_columns,...
                          latest_start,...
                          earliest_end,...
                          1,...
                          max_nobs,...
                          tol0,...
                          n_factors,...
                          other_factors,...
                          max_iterations,...
                          myfloor);

if isa(ts,'timetable')
    ts_filled = array2timetable(ts_filled,'RowTimes',ts.Properties.RowTimes);
    ts_factors = array2timetable(ts_factors,'RowTimes',ts.Properties.RowTimes);
    ts_resid = array2timetable(ts_resid,'RowTimes',ts.Properties.RowTimes);
end
