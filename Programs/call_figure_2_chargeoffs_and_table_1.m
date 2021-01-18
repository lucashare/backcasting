clear
setpath

%% Description:
    % This program replicates Figure 3 in "What drives bank peformance?" by
    % Luca Guerrieri and Collin Harkrader. 
    % 
%% Authors:
    % James Harkrader
    % Luca Guerrieri

%% Set parameters
number_of_macro_factors = 12;     % based on Bai and Ng (2002)
number_of_banking_factors = 1;  
    
%% Load data 
% Merger Adjusted Y-9c (Public Version)

if isunix
    datafilename = '../Data/may9c_public_20210108.csv';
else
    datafilename = '../Data/may9c_public_20210108.csv';
end

% set options for importing
opts = detectImportOptions(datafilename);
opts = setvartype(opts, {'total_interest_expense','total_noninterest_expense','total_noninterest_income','total_interest_income'}, 'double');  %or 'char' if you prefer

df_banking_data = readtable(datafilename,opts);
banks = unique(df_banking_data.ID_RSSD);
n_banks = length(banks);

% bank names
bank_names = readtable('../Data/correspondence_table.csv');

% macro data from the FredQD database --- see program
% fredfactors.m
load(correctslash('../Data/macro_pc.mat'),'fred_data','fred_date');


%% Reorder the bankig data
df_banking_data = join(df_banking_data,bank_names,'LeftKeys',{'ID_RSSD'},'RightKeys',{'ID_RSSD'});
df_banking_data = sortrows(df_banking_data,'ID_RSSD');

% subset the original table to include only chargeoffs
chargeoffs = df_banking_data(:,{'date','ID_RSSD','bank_name','bank_short_name','chargeoffs'});

tmp =chargeoffs{:,'chargeoffs'};
tmp = tmp*4;  % annualize data and express in percentage terms (the data are already normalized by total loans)

chargeoffs{:,'chargeoffs'}=tmp;
% now transpose the table for chargeoffs so that the chargeoffs for each
% bank are in a different column labeled with it short name
chargeoffs_transpose = table_transpose(chargeoffs);


%% standardize the dates and turn chargeoffs into a timetable object
dates = chargeoffs_transpose{:,'date'};
first_date = datevec(num2str(dates(1)),'yyyymmdd');
first_year = first_date(1);
first_month = first_date(2);

final_date = datevec(num2str(dates(end)),'yyyymmdd');
final_year = final_date(1);
final_month = final_date(2);

date = transpose(datetime(first_year,first_month-2,1):calquarters(1):datetime(final_year,final_month-2,1));

chargeoffs_transpose=table2timetable([table(date),chargeoffs_transpose(:,2:end)]); 

TR = timerange(chargeoffs_transpose.date(1),chargeoffs_transpose.date(end));


%% Get the macro principal components

% turn the data array into a timetable
fred_data_ts = table2timetable([table(fred_date),array2table(fred_data)]);

[~,macro_pc_ts]= backcast_ts(fred_data_ts(:,:),...
                          number_of_macro_factors );

macro_pc = macro_pc_ts{TR,:};
                      
%% Get the non-macro principal components                                                
% get the number of observations
nobs = size(macro_pc,1);

                     
%chargeoffs_transpose(:,{'STT','BNYM','BMO','CS','MS','GS'}) = [];
%n_banks = n_banks - 6;

% %% Drop banks with fewer than 20 observations
% for this_bank = 1:n_banks
%     nobs_vec(this_bank) = sum(~isnan(chargeoffs_transpose{:,this_bank}));    
%     
% end
% 
% 
% 
% disp('Dropped')
% chargeoffs_transpose.Properties.VariableNames(nobs_vec<20)
% 
% chargeoffs_transpose(:,nobs_vec<20)=[];
% 
% n_banks = n_banks - sum(nobs_vec<20);

%% Create a table with the bank names, short names, start quarter and end quarter
start_end_data_by_column = find_start_end_and_nans(chargeoffs_transpose{:,:});

start_dates_vec = chargeoffs_transpose.date(start_end_data_by_column(1,:));
end_dates_vec = chargeoffs_transpose.date(start_end_data_by_column(2,:));

start_quarter_vec = cellstr(strcat(num2str(year(start_dates_vec)),':',num2str(quarter(start_dates_vec))));
end_quarter_vec =  cellstr(strcat(num2str(year(end_dates_vec)),':',num2str(quarter(end_dates_vec))));  
bank_list = chargeoffs_transpose.Properties.VariableNames';
start_end_table = [table(bank_list), table(start_quarter_vec), table(end_quarter_vec)];

start_end_table = join(start_end_table,bank_names,'LeftKeys',{'bank_list'},'RightKeys',{'bank_short_name'});

start_end_table{:,'bank_name'} = upper(strrep(start_end_table{:,'bank_name'},'&','\&'));
% reorder columns
start_end_table = start_end_table(:,{'bank_name','bank_list','start_quarter_vec','end_quarter_vec'});
start_end_table.Properties.VariableDescriptions = {'Bank','Abbreviation','Data Start','Data End'};
% sort alphabetically
start_end_table = sortrows(start_end_table,{'bank_name'});

  max_iterations = 1e5;
  tol0 = 1e-3;
  myfloor = 0;

%% Backast the banking data and get the non-macro principal components
[data_matrix_long, factors_mat_long, non_macro_resid] = backcast_ts(chargeoffs_transpose{TR,:},...
                                                    number_of_banking_factors,...
                                                    [ones(nobs,1) macro_pc],max_iterations, tol0, myfloor);
 




%% Plot the fraction of the variation explained by the various factors 

var_labels = chargeoffs_transpose.Properties.VariableNames;

n_factors_total=number_of_banking_factors+size(macro_pc,2);

rsquare_mat = zeros(2, n_banks);

   intercept = ones(size(macro_pc,1),1);
   macro_xreg = [intercept macro_pc];
   banking_xreg = [intercept factors_mat_long];      
 
    for var_indx = 1:n_banks
       
        yreg =  ( data_matrix_long(:,var_indx)-mean(data_matrix_long(:,var_indx)) )...
                /std(data_matrix_long(:,var_indx) );
       
        [~,~, rsquare_mat(1,var_indx)] = estimate_ols(yreg,macro_xreg);
       
    end





%% Add non-banking factors to the plot of R-squares
for this_factor_indx=1:number_of_banking_factors
    for var_indx = 1:n_banks
        intercept = ones(size(macro_pc,1),1);
        xreg = factors_mat_long(:,this_factor_indx);
       
        yreg =  ( non_macro_resid(:,var_indx)-mean(non_macro_resid(:,var_indx)) )...
                /std(non_macro_resid(:,var_indx) );
       
        [~,~, rsquare_mat(this_factor_indx+1,var_indx)] = estimate_ols(yreg,xreg);
        rsquare_mat(this_factor_indx+1,var_indx) = rsquare_mat(this_factor_indx+1,var_indx)*(1-rsquare_mat(1,var_indx) );
       
    end
end

%%
figure
bar(1:n_banks, rsquare_mat','stack');
xticklabel_rotate90(1:n_banks,char(var_labels))

print -depsc2 chargeoffs_rsquare.eps

%% show adjusted R squares
figure
bar(1:n_banks,1- (1-[sum(rsquare_mat(1:end,:))]')*(nobs-1)/(nobs-number_of_macro_factors-number_of_banking_factors-1),'stack');
xticklabel_rotate90(1:n_banks,char(var_labels))

print -depsc2 chargeoffs_adjusted_rsquare.eps

%%

% var_labels = chargeoffs_transpose.Properties.VariableNames;
% col_idx = [1:length(var_labels)];
% bank_idx = col_idx(strcmp(var_labels, 'ALLY'));
% bank2_idx = col_idx(strcmp(var_labels, 'KEY'));
% figure   
% plot(chargeoffs_transpose.date(TR),data_matrix_long(:,bank_idx), 'r--')
% hold on
% plot(chargeoffs_transpose.date(TR),chargeoffs_transpose{TR,bank_idx}, 'k')
% hold on
% plot(chargeoffs_transpose.date(TR),chargeoffs_transpose{TR,bank2_idx},'blue-.')
% hold off
% legend(strcat(char(var_labels(bank_idx)), ' Backcasted'),...
%        strcat(char(var_labels(bank_idx)), ' Observed'),...
%        strcat(char(var_labels(bank2_idx)), ' Observed'))
% ylabel("Charge-offs (% of Total Loans and Leases)")
% 
% print -depsc2 backcasting_example.eps
% %%
% 
% save chargeoff_results

% Make plots for each bank
% for bank_indx = 1:n_banks
%     figure
%     plot(chargeoffs_transpose.date(TR),chargeoffs_transpose{TR,bank_indx},'k')
%     hold on
%     plot(chargeoffs_transpose.date(TR),data_matrix_long(:,bank_indx),'r--')
%     
%     title(chargeoffs_transpose.Properties.VariableNames(bank_indx))    
% end


