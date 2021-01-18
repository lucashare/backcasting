clear;
setpath

%% Description:
    % This program replicates Figure 3 in "What drives bank peformance?" by
    % Luca Guerrieri and Collin Harkrader. 
    % 
%% Authors:
    % James Harkrader
    % Luca Guerrieri

%% Set parameters
number_of_macro_factors = 12;  % based on the Bai and Ng (2002)
number_of_banking_factors = 1;

%% Load data 
% Merger Adjusted Y-9c (Public Version)
datafilename = '../Data/may9c_public_20210108.csv';

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
load(correctslash('../Data/macro_pc.mat'),'macro_pc_ts','fred_data','fred_date');


%% Reorder the bankig data
df_banking_data = join(df_banking_data,bank_names,'LeftKeys',{'ID_RSSD'},'RightKeys',{'ID_RSSD'});
df_banking_data = sortrows(df_banking_data,'ID_RSSD');


% create a table for PPNR and get its transpose, as above for chargeoffs
ppnr =  df_banking_data{:,'total_interest_income'}  + df_banking_data{:,'total_noninterest_income'}...
       -df_banking_data{:,'total_interest_expense'} - df_banking_data{:,'total_noninterest_expense'};
   
ppnr = ppnr*100;
   
df_banking_data = [df_banking_data,table(ppnr)];

ppnr = df_banking_data(:,{'date','ID_RSSD','bank_name','bank_short_name','ppnr'});

ppnr_transpose = table_transpose(ppnr);


% standardize the dates and turn chargeoffs and ppnr into time tables
dates = ppnr_transpose{:,'date'};
first_date = datevec(num2str(dates(1)),'yyyymmdd');
first_year = first_date(1);
first_month = first_date(2);

final_date = datevec(num2str(dates(end)),'yyyymmdd');
final_year = final_date(1);
final_month = final_date(2);

date = transpose(datetime(first_year,first_month-2,1):calquarters(1):datetime(final_year,final_month-2,1));

ppnr_transpose=table2timetable([table(date),ppnr_transpose(:,2:end)]); 

TR = timerange(ppnr_transpose.date(1),ppnr_transpose.date(end));

%% Get the macro principal components

% turn the data array into a timetable
fred_data_ts = table2timetable([table(fred_date),array2table(fred_data)]);

[~,macro_pc_ts]= backcast_ts(fred_data_ts,...
                          number_of_macro_factors);
                      
      
macro_pc = macro_pc_ts{TR,:};


% %% Drop banks with fewer than 20 observations
% for this_bank = 1:n_banks
%     nobs_vec(this_bank) = sum(~isnan(ppnr_transpose{:,this_bank}));    
%     
% end
% 
% 
% 
% disp('Dropped')
% ppnr_transpose.Properties.VariableNames(nobs_vec<20)
% 
% ppnr_transpose(:,nobs_vec<20)=[];
% 
% n_banks = n_banks - sum(nobs_vec<20);



%% Get the non-macro principal components                                                
% get the number of observations
nobs = size(macro_pc,1);


% backast the banking data and get the non-macro principal components
[data_matrix_long, factors_mat_long,non_macro_resid] = backcast_ts(ppnr_transpose{TR,:},...
                                                        number_of_banking_factors,...
                                                        [ones(nobs,1) macro_pc]);

                                                
                                                                                           

%% Plot the fraction of the variation explained by the various factors 
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


%





%% Add banking factors to the plot of R-squares
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
var_labels = ppnr_transpose.Properties.VariableNames;

xticklabel_rotate90(1:n_banks,char(var_labels))
legend('Macro Factors','Banking Factor','Location','NorthWest')

print -depsc2 ppnr_rsquare.eps


%% show adjusted R squares
figure
bar(1:n_banks,1- (1-[sum(rsquare_mat(1:end,:))]')*(nobs-1)/(nobs-number_of_macro_factors-number_of_banking_factors-1),'stack');
xticklabel_rotate90(1:n_banks,char(var_labels))

print -depsc2 ppnr_adjusted_rsquare.eps

% %%
% var_labels = ppnr_transpose.Properties.VariableNames;
% col_idx = [1:length(var_labels)];
% bank_idx = col_idx(strcmp(var_labels, 'GS'));
% bank2_idx = col_idx(strcmp(var_labels, 'C'));
% figure   
% plot(ppnr_transpose.date(TR),data_matrix_long(:,bank_idx), 'r--')
% hold on
% plot(ppnr_transpose.date(TR),ppnr_transpose{TR,bank_idx}, 'k')
% hold on
% plot(ppnr_transpose.date(TR),ppnr_transpose{TR,bank2_idx},'blue-.')
% hold off
% legend(strcat(char(var_labels(bank_idx)), ' Backcasted'),...
%        strcat(char(var_labels(bank_idx)), ' Observed'),...
%        strcat(char(var_labels(bank2_idx)), ' Observed'))
% ylabel("PPNR (% of Average Assets)")
% 
% print -depsc2 backcasting_example.eps
