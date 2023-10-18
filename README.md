# Backward-trajectories-in-R
The openair (https://cran.r-project.org/web/packages/openair/openair.pdf) is an excellent package for air quality data analysis in R. It allows easy imports of backward trajectory (BWT) data for a list of major sites around the world. However, importing BWT data for sites that are not on the list may be problematic. Therefore, I created a simple R script that processes the raw backward trajectory (BWT) data, as obtained from the HYSPLIT Web, and outputs a single file ready to be used by the openair. BWT data and air pollution data from Chiang Mai, Thailand, are used for demonstration.

**BWT_in_R.R** - this script (1) compiles raw BWT data stored in separate text files and outputs a single dataframe ready to be used in openair (2) merges the BWT data with air pollution data and (3) provides examples of their use by the openair functions

**BWT_120h** - this folder contains the raw BWT data

**BWT_500m_120h.csv** - dataframe containing the merged and processed raw BWT data

**PM_Daily.xlsx** - dataframe containing daily PM2.5 data from Chiang Mai

**GUIDE.docx** - brief guide shows how to use the R script
