function [total_resid_mat, ...
    total_r_square_mat, ...
    ols_beta_mat,...
    factors,...
    total_fitted_mat]=...
    factor_regress(other_factors,macro_resid_mat,n_factors,...
    data_matrix)

n_other_factors = size(other_factors,2);

n_cols = size(data_matrix,2);

% get predictor series principal components

pca_x_mat = macro_resid_mat;

% squeeze out columns that have nan before computing the principal
% components
pca_x_mat = pca_x_mat(:,sum(isnan(pca_x_mat))==0);

[factors frac_var] = pca_jch(pca_x_mat,n_factors);

ols_beta_mat = zeros(n_other_factors+n_factors,n_cols);
total_resid_mat = nan*data_matrix;
total_r_square_mat = zeros(1,n_other_factors+n_factors);

total_fitted_mat = nan*data_matrix;

for this_col = 1:n_cols
    
    % record second step r squared
    
    yreg = data_matrix(:,this_col);
    xreg = [other_factors factors];
    [ols_beta_mat(:,this_col), total_resid_mat(:,this_col), total_r_square_mat(this_col), total_fitted_mat(:,this_col)] = estimate_ols(yreg,xreg);
    
    
end


