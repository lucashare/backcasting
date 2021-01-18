clear; close all; clc;
setpath

%% Merger Adjusted FR Y-9c (Public Version)
if isunix
    datafilename = '../Data/may9c_public_20210108.csv';

else
    datafilename = '..\Data\may9c_public_20210108.csv';
end

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
bank_names = readtable('../Data/correspondence_table.csv');

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


%% create a table for PPNR and get its transpose, as above for chargeoffs
ppnr =  df_banking_data{:,'total_interest_income'}  + df_banking_data{:,'total_noninterest_income'}...
       - df_banking_data{:,'total_interest_expense'} - df_banking_data{:,'total_noninterest_expense'};
   
df_banking_data = [df_banking_data,table(ppnr)];
ppnr = df_banking_data(:,{'date','ID_RSSD','bank_name','bank_short_name','ppnr'});
ppnr_transpose = table_transpose(ppnr);

%% Standardize the dates and turn chargeoffs and ppnr into time tables
dates = ppnr_transpose{:,'date'};
first_date = datevec(num2str(dates(1)),'yyyymmdd');
first_year = first_date(1);
first_month = first_date(2);

final_date = datevec(num2str(dates(end)),'yyyymmdd');
final_year = final_date(1);
final_month = final_date(2);

date = transpose(datetime(first_year,first_month-2,1):calquarters(1):datetime(final_year,final_month-2,1));

%% Final input data
ppnr_transpose = table2timetable([table(date), ppnr_transpose(:,2:end)]); 
chargeoffs_transpose = table2timetable([table(date), chargeoffs_transpose(:,2:end)]); 


var_labels = chargeoffs_transpose.Properties.VariableNames;
col_idx = [1:length(var_labels)];
bank_idx = col_idx(strcmp(var_labels, 'JPM'));
bank2_idx = col_idx(strcmp(var_labels, 'BAC'));
% Figure 1, PPNR
figure 
ppnr_mat = ppnr_transpose{:,:};
plot(ppnr_mat(:,[2,6])*400)
plot(ppnr_transpose.date, ppnr_mat(:,bank_idx)*400,'k')
hold on
plot(ppnr_transpose.date, ppnr_mat(:,bank2_idx)*400,'b-.')

ylabel("PPNR (% of Average Assets)")
legend(strcat(char(var_labels(bank_idx)), ' PPNR'),...
       strcat(char(var_labels(bank2_idx)), ' PPNR'));
   
print -depsc2 figure_ppnr.eps

% Figure 1, Chargeoffs
figure 
nchg_mat = chargeoffs_transpose{:,:};
plot(chargeoffs_transpose.date, nchg_mat(:,bank_idx)*4,'k')
hold on
plot(chargeoffs_transpose.date, nchg_mat(:,bank2_idx)*4,'b-.')

ylabel("Charge-offs (% of Total Loans and Leases)")
legend(strcat(char(var_labels(bank_idx)), ' Charge-offs'),...
       strcat(char(var_labels(bank2_idx)), ' Charge-offs'));

print -depsc2 figure_chargeoffs.eps
