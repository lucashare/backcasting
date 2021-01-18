function data_array_info=find_start_end_and_nans(data_array)
% the first row of data_array_info contains the position of the first 
% observation within data_array colum by column 
% the second row contains the position of the last observation
% the following rows report the positions of NaNs that are found between
% the first and last observation

% find flags for the NaNs
data_matrix_nan = isnan(data_array);

% initialize the output matrix to have NaNs and the same dimensions as the
% input matrix
data_array_info = nan(size(data_array,1),size(data_array,2));


% loop through colum by colum
n_columns = size(data_array,2);
for this_column = 1:n_columns
    
    % get start and end positions
    start_pos = find(~data_matrix_nan(:,this_column),1,'first');
    end_pos = find(~data_matrix_nan(:,this_column),1,'last');
    
    % find any NaN between 
    ind_nan = find(data_matrix_nan(start_pos:end_pos,this_column));
    
    % store info
    data_array_info(1,this_column) = start_pos;
    data_array_info(2,this_column) = end_pos;
    data_array_info(3:2+length(ind_nan),this_column) = ind_nan+start_pos-1;
end
