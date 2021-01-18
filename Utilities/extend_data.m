function [extended_bal_sheet_to_assets, extended_bank_id]=...
    extend_data(bal_sheet_to_assets, bank_id, bank_id_list,...
    this_step_nobs,ss_bank_id_list, ss_nobs, var_labels, ...
    regression_items, short_ols_beta_mat, ...
    macro_factors, long_nonmacro_factors_mat)

% make space in the balance sheet data for the backcast observations
% fill unavailable observations with NaN
[extended_bal_sheet_to_assets, extended_bank_id] =...
    reorder_bal_sheet(bal_sheet_to_assets,bank_id,bank_id_list,this_step_nobs);

ss_n_banks = length(ss_bank_id_list);
n_regression_items = length(regression_items);

for bank_indx = 1:ss_n_banks
    % construct fitted values based on factor loading from Step 1
    % and factors from Step 2
    this_bank_id = ss_bank_id_list(bank_indx);
    
    this_bank_data = nan*zeros(this_step_nobs,size(bal_sheet_to_assets,2));
    
    for item_indx = 1:n_regression_items
        pos_item = strmatch(regression_items(item_indx),var_labels,'exact');
        xreg = [ones(this_step_nobs,1) macro_factors long_nonmacro_factors_mat(:,:,item_indx)];
        ols_beta = short_ols_beta_mat(:,bank_indx,item_indx);
        fitted = xreg*ols_beta;
        this_bank_data(:,pos_item) = fitted;
    end
    
    pos_bank = find(this_bank_id == extended_bank_id);
    pos_overwrite = pos_bank(isnan(extended_bal_sheet_to_assets(pos_bank,2))==1);
    extended_bal_sheet_to_assets(pos_overwrite,:) = this_bank_data(1:this_step_nobs-ss_nobs(bank_indx),:);
end
