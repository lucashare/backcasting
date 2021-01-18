
function [ols_beta_mat,macro_resid_mat, macro_r_square_mat,macro_fitted_mat ]=...
    predictor_regress_general(short_macro_factors,data_matrix_modified)

nobs = size(short_macro_factors,1);

xreg = [short_macro_factors];

n_cols = size(data_matrix_modified,2);

n_macro_factors = size(short_macro_factors,2);

macro_r_square_mat = zeros(1,n_cols);
ols_beta_mat = zeros(n_macro_factors,n_cols);
macro_resid_mat = nan*data_matrix_modified;
macro_fitted_mat = nan*data_matrix_modified;

for this_col = 1:n_cols
    yreg = data_matrix_modified(:,this_col);
    
    [ols_beta_mat(:,this_col), macro_resid_mat(:,this_col),...
        macro_r_square_mat(this_col), macro_fitted_mat(:,this_col)] = ...
        estimate_ols(yreg,xreg);
    
end



