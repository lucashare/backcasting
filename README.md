# backcasting
===========================================================================
DESCRIPTION

The utility backcast_ts.m backcasts data and extracts principal components 
From a dataset with missing observations at the beginning or end. It can be 
found in the Utilities folder. 

This repository contains files for the replication of the figures and table 
"What Drives Bank Performance" by Luca Guerrieri and James Collin Harkrader. 
The replication programs for the paper provide examples for calling backcast_ts.

load_macro_data creates a .mat file with the formmatted macro data from 
FRED QD and should be called before any other program.

The FRED QD database included in this distribution can be updated from:
https://research.stlouisfed.org/econ/mccracken/fred-databases/

The main programs are in the directory Programs
load_macro_data.m can be used to update the macro dataset from Fred QD
call_figure1.m reproduces Figure 1 from the paper.
call_figure2_chargeoffs_and_table1.m reproduces the chargeoffs panels of 
                                     Figure 2 and Table 1.
call_figure2_ppnr.m reproduces the ppnr panels of Figure 2.
call_figure3.m reproduces Figure 3.
setpath.m is used to put the Utilities folder on the Matlab search path.

===========================================================================
