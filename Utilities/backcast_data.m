function [extended_bal_sheet_to_assets,extended_bank_id]  = backcast_data(bal_sheet_to_assets,bank_id,ss_nobs,fs_nobs,macro_factors,...
                       bank_id_list,regression_items,var_labels,tol0,...
                       n_nonmacro_factors,fs_bank_id_list, ss_bank_id_list)


back_cast_steps = [sort(unique(ss_nobs)); fs_nobs];

nfactors = size(macro_factors,2);


% stack residuals by bank (rows) and items (columns)
% but leave the first column to define a bank id.

% check if still used
nsteps = length(back_cast_steps);

extended_bal_sheet_to_assets = [];
extended_bank_id = [];
%% Step 1: first run on shortest sample

% update bank_id_list
% update bal_sheet_to_assets
% update bank_id

this_step_nobs = back_cast_steps(1);

[short_bal_sheet_to_assets, short_bank_id] =...
    reorder_bal_sheet(bal_sheet_to_assets,bank_id,bank_id_list,this_step_nobs);

short_macro_factors = macro_factors(end-this_step_nobs+1:end,:);

[~,short_macro_resid_mat]=...
    macro_regress(short_macro_factors,short_bal_sheet_to_assets,...
    bank_id_list,short_bank_id,regression_items,var_labels,nfactors,tol0);

% Extract non-macro principal components and run the second-step
% regression.
% Run the regression with both macro and nonmacro factors.

[short_resid_mat, ...
    short_r_square_mat, ...
    short_ols_beta_mat]=...
    nonmacro_regress(short_macro_factors,short_macro_resid_mat,n_nonmacro_factors,...
    this_step_nobs,short_bal_sheet_to_assets,...
    bank_id_list,short_bank_id,regression_items,var_labels,tol0);


%% Step 2: now run on longest sample

% update bank_id_list
% update bal_sheet_to_assets
% update bank_id



this_step_nobs = back_cast_steps(end);

[long_bal_sheet_to_assets, long_bank_id] =...
    reorder_bal_sheet(bal_sheet_to_assets,bank_id,fs_bank_id_list,this_step_nobs);


[~,long_macro_resid_mat]=...
    macro_regress(macro_factors,long_bal_sheet_to_assets,...
    fs_bank_id_list,long_bank_id,regression_items,var_labels,nfactors,tol0);


% Extract non-macro principal components and run the second-step
% regression.
% Run the regression with both macro and nonmacro factors.

[~, ...
    ~, ...
    ~,...
    long_nonmacro_factors_mat]=...
    nonmacro_regress(macro_factors,long_macro_resid_mat,n_nonmacro_factors,...
    this_step_nobs,long_bal_sheet_to_assets,...
    fs_bank_id_list,long_bank_id,regression_items,var_labels,tol0);

%% Step 3: update data by backcasting
this_step_nobs = back_cast_steps(end);

 [extended_bal_sheet_to_assets, extended_bank_id]=...
    extend_data(bal_sheet_to_assets,bank_id,bank_id_list,this_step_nobs,...
    ss_bank_id_list, ss_nobs, var_labels, regression_items, short_ols_beta_mat, ...
    macro_factors, long_nonmacro_factors_mat);

%% Step 4 iterate to convergence 
% inner loop is similar to step 2, but with different ols_beta_mat (factor
% loadings) and different nonmacro factors.

dist = 10;
iter = 0;
dist_tol = 10^-8;
while (dist > dist_tol && iter < 100)
iter = iter+1
    
[~,extended_macro_resid_mat, ...
    extended_macro_r_square_mat]=...
    macro_regress(macro_factors,extended_bal_sheet_to_assets,...
    bank_id_list,extended_bank_id,regression_items,var_labels,nfactors,tol0);

[extended_total_resid_mat, ...
    extended_total_r_square_mat, ...
    extended_ols_beta_mat,...
    extended_nonmacro_factors_mat]=...
        nonmacro_regress(macro_factors,extended_macro_resid_mat,n_nonmacro_factors,...
        this_step_nobs,extended_bal_sheet_to_assets,...
        bank_id_list,extended_bank_id,regression_items,var_labels,tol0);

[new_extended_bal_sheet_to_assets, extended_bank_id]=...
    extend_data(bal_sheet_to_assets,bank_id,bank_id_list,this_step_nobs,...
    ss_bank_id_list, ss_nobs, var_labels, regression_items, extended_ols_beta_mat, ...
    macro_factors, extended_nonmacro_factors_mat);

dist = max(max(abs(extended_bal_sheet_to_assets-new_extended_bal_sheet_to_assets)))

extended_bal_sheet_to_assets=new_extended_bal_sheet_to_assets;

end

if dist<dist_tol
    display('Achieved desired convergence on backcasting')
else
    display('Not achieved desired convergence on backcasting')
end


