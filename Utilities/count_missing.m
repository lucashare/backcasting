function [nan_rows_full, nan_rows_modified] = count_missing(data_col_full,data_col_modified,start_max,end_min)

nan_data_col_modified = find(isnan(data_col_modified));
nan_data_col_full = find(isnan(data_col_full));

 %isempty(nan_data_col_full) == 0
    nan_rows_full = intersect(nan_data_col_full(nan_data_col_full>start_max),nan_data_col_full(nan_data_col_full<end_min));
    nan_rows_modified = nan_data_col_modified;