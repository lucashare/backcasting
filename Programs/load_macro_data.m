clear
setpath

% =========================================================================
% DESCRIPTION 
% This script loads in a FRED-MD dataset, processes the dataset, and then
% estimates factors.
%
% -------------------------------------------------------------------------
% BREAKDOWN OF THE SCRIPT
% 
% Part 1: Load and label FRED-MD data.
%
% Part 2: Process data -- transform each series to be stationary and remove
%         outliers.
%
% Part 3: Estimate factors and compute R-squared and marginal R-squared. 
%
% -------------------------------------------------------------------------
% AUXILIARY FUNCTIONS
% List of auxiliary functions to be saved in same folder as this script.
%
%   prepare_missing() - transforms series based on given transformation
%       numbers
%
%   remove_outliers() - removes outliers
%
%   factors_em() - estimates factors
%
%   mrsq() - computes R-squared and marginal R-squared from factor 
%       estimates and factor loadings
%
% -------------------------------------------------------------------------
% NOTES
% Authors: Michael W. McCracken and Serena Ng
% Date: 9/5/2017
% Version: MATLAB 2014a
% Required Toolboxes: None
%
% Luca Guerrieri and Collin Harkrader modified this program to save the
% transformed Fred dataset as a timetable
% -------------------------------------------------------------------------
% PARAMETERS TO BE CHANGED

% File name of desired FRED-MD vintage
csv_in='../Data/current.csv';

% Type of transformation performed on each series before factors are
% estimated
%   0 --> no transformation
%   1 --> demean only
%   2 --> demean and standardize
%   3 --> recursively demean and then standardize
DEMEAN=2;

% Information criterion used to select number of factors; for more details,
% see auxiliary function factors_em()
%   1 --> information criterion PC_p1
%   2 --> information criterion PC_p2
%   3 --> information criterion PC_p3
jj=1;

% Maximum number of factors to be estimated; if set to 99, the number of
% factors selected is forced to equal 8
kmax=14;

% =========================================================================
% PART 1: LOAD AND LABEL DATA

% Load data from CSV file
dum=importdata(csv_in,',');

% Variable names
series=dum.textdata(1,2:end);

% Transformation numbers
tcode=dum.data(2,:);

% Raw data
rawdata=dum.data(3:end,:);

% Month/year of final observation
first_datevec = datevec(dum.textdata(4,1));
first_month = first_datevec(2);
first_year = first_datevec(1);

final_datevec=datevec(dum.textdata(end,1));
final_month=final_datevec(2);
final_year=final_datevec(1);

% Dates (quarterly) are of the form YEAR+MONTH/12
% e.g. March 1970 (the first quarter of 1970) is represented as 1970
%      June 1970 (the second quater of 1970) is represented at 1970.25
% Dates go from 1959:01 to final_year:final_month (see above)
dates = (1959:1/4:final_year+(final_month-3)/12)';

mydates = transpose(datetime(first_year,first_month-2,1):calquarters(1):datetime(final_year,final_month-2,1));
%dateshift(mydates,'end','month')

% T = number of months in sample
T=size(dates,1);
rawdata=rawdata(1:T,:);

% =========================================================================
% PART 2: PROCESS DATA

% Transform raw data to be stationary using auxiliary function
% prepare_missing()
yt=prepare_missing(rawdata,tcode);

% Reduce sample to usable dates: remove first two months because some
% series have been first differenced
yt=yt(2:T,:);
dates=dates(2:T,:);
mydates = mydates(2:T,:);

% Remove outliers using auxiliary function remove_outliers(); see function
% or readme.txt for definition of outliers
%   data = matrix of transformed series with outliers removed
%   n = number of outliers removed from each series
[data,n]=remove_outliers(yt);

% =========================================================================
% PART 3: ESTIMATE FACTORS AND COMPUTE R-SQUARED 

% Estimate factors using function factors_em()
%   ehat    = difference between data and values of data predicted by the 
%             factors
%   Fhat    = set of factors
%   lamhat  = factor loadings
%   ve2     = eigenvalues of data'*data
%   x2      = data with missing values replaced from the EM algorithm
[ehat,Fhat,lamhat,ve2,x2] = factors_em(data,kmax,jj,DEMEAN);

% Compute R-squared and marginal R-squared from estimated factors and
% factor loadings using function mrsq()
%   R2      = R-squared for each series for each factor
%   mR2     = marginal R-squared for each series for each factor
%   mR2_F   = marginal R-squared for each factor
%   R2_T    = total variation explained by all factors
%   t10_s   = top 10 series that load most heavily on each factor
%   t10_mR2 = marginal R-squared corresponding to top 10 series
%             that load most heavily on each factor 
[R2,mR2,mR2_F,R2_T,t10_s,t10_mR2] = mrsq(Fhat,lamhat,ve2,series);

% save principal components to disk

date = mydates;
macro_pc_ts = table2timetable([table(date),array2table(Fhat)]);

fred_data = data;
fred_date = date;
save(correctslash('../Data/macro_pc.mat'),'macro_pc_ts','fred_data','fred_date');

