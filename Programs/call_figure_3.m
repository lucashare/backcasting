clear; close all; clc;
setpath


%% Merger Adjusted FR Y-9c (Public Version)
if isunix
    datafilename = '../Data/may9c_public_20210108.csv';
else
    datafilename = '..\Data\may9c_public_20210108.csv';
end

%
number_of_macro_factors = 12;
number_of_banking_factors = 1;

%%  set options for importing
opts = detectImportOptions(datafilename);
opts = setvartype(opts, {'total_interest_expense','total_noninterest_expense','total_noninterest_income','total_interest_income'}, 'double');  %or 'char' if you prefer

%% Import FR Y-9c Banking Data
df_banking_data = readtable(datafilename,opts);

%% Unique list of banks (ID RSSDs)
banks = unique(df_banking_data.ID_RSSD);

%% Bumber of banks
n_banks = length(banks);

%% Load and Merge Bank Names, Sort data by bank identifier (ID_RSSD)
if isunix
    bank_names = readtable('../Data/correspondence_table.csv');
else
    bank_names = readtable('..\Data\correspondence_table.csv');
end

df_banking_data = join(df_banking_data,bank_names,'LeftKeys',{'ID_RSSD'},'RightKeys',{'ID_RSSD'});
df_banking_data = sortrows(df_banking_data, 'ID_RSSD');

%% Select chargeoffs variable
chargeoffs = df_banking_data(:,{'date','ID_RSSD','bank_name','bank_short_name','chargeoffs'});

%% now transpose the table for chargeoffs so that the chargeoffs for each
%% bank are in a different column labeled with it short name
chargeoffs_transpose = table_transpose(chargeoffs);


%% Standardize the dates and turn chargeoffs and ppnr into time tables
dates = chargeoffs_transpose{:,'date'};
first_date = datevec(num2str(dates(1)),'yyyymmdd');
first_year = first_date(1);
first_month = first_date(2);

final_date = datevec(num2str(dates(end)),'yyyymmdd');
final_year = final_date(1);
final_month = final_date(2);

date = transpose(datetime(first_year,first_month-2,1):calquarters(1):datetime(final_year,final_month-2,1));

%% Final input data
chargeoffs_transpose = table2timetable([table(date), chargeoffs_transpose(:,2:end)]); 




% load the macro factors and set the time range
load(correctslash('../Data/macro_pc.mat'),'fred_data','fred_date');

% turn the data array into a timetable
fred_data_ts = table2timetable([table(fred_date),array2table(fred_data)]);

% take the latest starting date and the earliest end date
TR = timerange(max(fred_data_ts.fred_date(1),chargeoffs_transpose.date(1)),min(fred_data_ts.fred_date(end),chargeoffs_transpose.date(end)));


macro_data_ts = table2timetable([table(fred_date),array2table(fred_data)]);

%% Get the macro PCs
[~,macro_pc_ts] = backcast_ts(macro_data_ts,...
                         number_of_macro_factors);
macro_pc = macro_pc_ts(TR,:);
nobs = size(macro_pc,1);
macro_pc.constant = ones(nobs,1);



%% Backast data for chargeoffs with the baseline model
  max_iterations = 1e5;
  tol0 = 1e-3;
  myfloor = 0;
  
[chargeoffs_data_matrix_long,...
    chargeoffs_factors_mat_long,...
    chargeoffs_non_macro_resid] = backcast_ts(chargeoffs_transpose(TR,:),...
                                                number_of_banking_factors,...
                                                macro_pc_ts(TR,1:number_of_macro_factors),...
                                                max_iterations,...
                                                tol0,...
                                                myfloor);


%% POOS Example
var_labels = chargeoffs_transpose.Properties.VariableNames;
col_idx = [1:length(var_labels)];
bank_idx = col_idx(strcmp(var_labels, 'JPM'));
number_of_macro_factors = 12;
number_of_banking_factors = 1;

% drop the first 50 opbservations
TR_POFS_Backcast = timerange(max(fred_data_ts.fred_date(1),chargeoffs_transpose.date(1)),min(fred_data_ts.fred_date(end),chargeoffs_transpose.date(50)));
chargeoffs_transpose_pseudo_ofs = chargeoffs_transpose;
chargeoffs_transpose_pseudo_ofs(TR_POFS_Backcast, bank_idx) = {NaN};

[chargeoffs_data_matrix_long_pseudo_ofs,...
    chargeoffs_factors_mat_long_pseudo_ofs,...
    chargeoffs_non_macro_resid_pseudo_ofs] = backcast_ts(chargeoffs_transpose_pseudo_ofs(TR,:),...
                                                number_of_banking_factors,...
                                                macro_pc_ts(TR,1:number_of_macro_factors),...
                                                max_iterations,...
                                                tol0,...
                                                myfloor);

number_of_banking_factors = 1;
intercept = ones(size(chargeoffs_transpose_pseudo_ofs(TR,:),1),1);
[chargeoffs_data_matrix_long_pseudo_ofs_no_macro_factors,...
    chargeoffs_factors_mat_long_pseudo_ofs_no_macro_factors,...
    chargeoffs_non_macro_resid_pseudo_ofs_no_macro_factors] = backcast_ts(chargeoffs_transpose_pseudo_ofs(TR,:),...
                                                number_of_banking_factors,...
                                                intercept,...
                                                max_iterations,...
                                                tol0,...
                                                myfloor);
                                                                           
                                          
number_of_banking_factors = 5;
[chargeoffs_data_matrix_long_pseudo_ofs_no_macro_factors_n_baing,...
    chargeoffs_factors_mat_long_pseudo_ofs_no_macro_factors_n_baing,...
    chargeoffs_non_macro_resid_pseudo_ofs_no_macro_factors_n_baing] = backcast_ts(chargeoffs_transpose_pseudo_ofs(TR,:),...
                                                number_of_banking_factors,...
                                                intercept,...
                                                max_iterations,...
                                                tol0,...
                                                myfloor);

%%
figure 
plot(chargeoffs_transpose.date(TR),chargeoffs_data_matrix_long_pseudo_ofs{:,bank_idx}*4, 'r--')
hold on
plot(chargeoffs_transpose.date(TR),chargeoffs_data_matrix_long_pseudo_ofs_no_macro_factors{:,bank_idx}*4, 'g:','linewidth',2)
hold on
plot(chargeoffs_transpose.date(TR),chargeoffs_data_matrix_long_pseudo_ofs_no_macro_factors_n_baing{:,bank_idx}*4, 'b-.')
hold on
plot(chargeoffs_transpose.date(TR),chargeoffs_data_matrix_long{:,bank_idx}*4, 'k-')
ylim([0, 5])
hold off
legend("POOS Backcast",...
    "POOS Backcast \newline(No Macro Factors,\newline 1 Banking Factor)",...
    "POOS Backcast \newline(No Macro Factors,\newline 5 Banking Factors)",...
    "Observed")
ylabel("Charge-offs (% of Total Loans and Leases)")

print -depsc2 psuedo-out-of-sample.eps