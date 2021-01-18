function [data_matrix_long, factors_mat_long, predictor_resid_mat_long]  = ...
    backcast_data_general(data_matrix,...
                          data_matrix_modified,...
                          data_matrix_modified_long,...
                          start_max,...
                          end_min,...
                          start_row_long_data,...
                          end_row_long_data,...
                          tol0,...
                          n_factors,...
                          other_factors,...
                          max_iter,...
                          myfloor)


% =========================================================================
% DESCRIPTION
          % This routine takes as input an unbalanced dataset with an arbitrary pattern of missing observations. For contiguously missing observations 
          % at the beginning or at the end of each series, the routine relies on an extension of the method of Stock and Watson as described in the
          % Guerrieri, L. and C. Harkrader 'What Drives Bank Performance,' which allows for use of external factors. Missing observations away from the 
          % begging or end sections of each series are filled in using cubic splines.
% -------------------------------------------------------------------------
% INPUTS
          % data_matrix:               matrix of data with missing values
          % data_matrix_modified:      matrix of data from end of prepended NaNs to start of NaNs (matrix is as long as shortest series)
          % data_matrix_modified_long: matrix subset of columns with sufficiently long data to be used  to extract PCs for the first iteration of the procedure 
          % start_max:                 integer indicating row in data_matrix corresponding to first row of data_matrix_modified 
          % end_min:                   integer indicating row in data_matrix corresponding to last row of data_matrix_modified
          % start_row_long_data:        
          % end_row_long_data:  
          % tol0:                      integer indicating maximum absolute difference in forecast between iterations.
          % other_factors:             matrix of factors to be controlled for before running the principal 
          % components on the residuals (the input factors is conformable with data_matrix)
          % n_factors:                 matrix of factors to extract from running the principal compondents on the
          % residuals (n_factors should be conformable with data_matrix)
          % max_iter:                  integer number of iterations before procedure aborts
% OUTPUTS
          % data_matrix_long: timetable of the same shape ts but with missing values filled in.
          % factors_mat_long: timetable with factors extracted from the time table ts.
          % predictor_resid_mat_long: residuals for each series in data_matrix_long not explained by external factors or additiona factors extracted from ts.
% -------------------------------------------------------------------------
% BREAKDOWN OF THE FUNCTION
% Part 1: 
% Part 2: 
% Part 3: 
% -------------------------------------------------------------------------
% NOTES
% Authors: Luca Guerrieri & James Collin Harkrader
% Date: 1/6/2020
% Version: MATLAB 2018b, 2019b
% Required Toolboxes: None
%
% =========================================================================

dist = 1e3;
iter = 0;

n_other_factors = size(other_factors,2);

% stack residuals by bank (rows) and items (columns)
% but leave the first column to define a bank id.

%% Step 1: First run on shortest sample

other_factors_short = other_factors(start_max:end_min,:);
other_factors_long = other_factors(start_row_long_data:end_row_long_data,:);
data_matrix_long = data_matrix(start_row_long_data:end_row_long_data,:);
data_matrix_long_with_nans = data_matrix_long;

[~,other_factors_resid_mat_short]=...
    predictor_regress_general(other_factors_short,data_matrix_modified);

%% Extract factors (N) principal components and run the second-step regression.
%% Run the regression with both other and principal factors.

[resid_mat_short, ...
    r_square_mat_short, ...
    ols_beta_mat_short]=...
    factor_regress(other_factors_short,...
                            other_factors_resid_mat_short,...
                            n_factors,...
                            data_matrix_modified);


%% Step 2: now run on longest sample

[~,predictor_resid_mat_long]=...
    predictor_regress_general(other_factors_long,...
                          data_matrix_modified_long);

% Extract residual principal components and run the second-step
% regression.
% Run the regression with both
% candidate predictor series other_factors (N) and residual other_factors.

[~,~,~,...
    factors_mat_long]=...
    factor_regress(other_factors_long,...
          predictor_resid_mat_long,...
          n_factors,...
          data_matrix_modified_long);

%% Step 3: Update Data by Backcasting
[data_matrix_long] = ...
    extend_data_general(data_matrix_long_with_nans,...
                        ols_beta_mat_short, ...
                        other_factors_long,...
                        factors_mat_long,...
                        myfloor);

%% Step 4: Iterate to convergence 
% inner loop is similar to step 2, but with different ols_beta_mat (factor loadings) and different residual other_factors.


while (dist > tol0 && iter < max_iter)
  
  iter = iter + 1;

  disp("Iteration:");
  disp(iter);
   
  [~,predictor_resid_mat_long]=...
      predictor_regress_general(other_factors_long,...
                            data_matrix_long);


  [total_resid_mat_long, ...
      total_r_square_mat_long, ...
      ols_beta_mat_long,...
      factors_mat_long]=...
      factor_regress(other_factors_long,...
      predictor_resid_mat_long,n_factors,...
      data_matrix_long);
      

   [data_matrix_long_new] = ...
      extend_data_general(data_matrix_long_with_nans,...
                          ols_beta_mat_long, ...
                          other_factors_long, factors_mat_long,myfloor);


  %% Distance measure between interations
  dist = max(max(abs(data_matrix_long-data_matrix_long_new)));

  disp("Distance:");
  disp(dist);

  data_matrix_long = data_matrix_long_new;


end

if dist < tol0
    display('Achieved desired convergence on backcasting')
else
    display('Not achieved desired convergence on backcasting')
end


