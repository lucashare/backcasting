function [data_matrix_filled_in]=...
    extend_data_general(data_matrix, ols_beta_mat_short, ...
    					macro_factors_long, nonmacro_factors_mat_long,myfloor)

        xreg = [macro_factors_long nonmacro_factors_mat_long];
        fitted = xreg*ols_beta_mat_short;
        
    data_matrix_filled_in = data_matrix;
    data_matrix_filled_in(isnan(data_matrix)) = fitted(isnan(data_matrix));
    
    if ~isempty(data_matrix_filled_in(data_matrix_filled_in<myfloor))
    data_matrix_filled_in(data_matrix_filled_in<myfloor)=myfloor;
    end