#<--------------------------------- IMPORTS --------------------------------->
library(openxlsx)
library(openair)
library(lubridate)
library(dplyr)

#<--------------------------------- BWT data preparation (run once) --------------------------------->
#This function combines all backward trajectory (BWT) files from a specified folder
combine_files <- function(folder_path, traj_length){
  bwt_file <- data.frame()
  file_list <- list.files(folder_path, pattern = "*", full.names = TRUE) #list of filenames in the specified folder
  n_files <- 0
  for (i in seq_along(file_list)){
    filename <- file_list[i]
    tryCatch({
      cfile <- read.table(filename, skip = max(0, length(readLines(filename)) - traj_length - 1)) #read the last x+1 lines if there are x BWTs
      cfile$V1 <- i #the trajectory number
      bwt_file <- rbind(bwt_file, cfile)
      n_files <- n_files + 1
    }, error = function(e) {
      print(paste("Error occured at file:",filename))
    })
  }
  print(paste(n_files, " trajectories were successfully combined"))
  return(bwt_file)
}

#This function assigns appropriate column names to BWT data frame
prep_data <- function(bwt_file){
  colnames(bwt_file) <- c("traj",
                          "grid",
                          "year",
                          "month",
                          "day",
                          "hour",
                          "min",
                          "hourF",
                          "hour.inc",
                          "lat",
                          "lon",
                          "height",
                          "pressure")
  
  bwt_file <- bwt_file[, !names(bwt_file) %in% c("grid","min","hourF","pressure")] #drop not needed columns
  bwt_file$date2 <- ISOdatetime(2020, bwt_file$month, bwt_file$day, bwt_file$hour, 0, 0, tz="UTC") #time zone should be specified!
  bwt_file$date <- bwt_file$date2 - as.difftime(bwt_file$hour.inc, units="hours")
  print("The data preparation was successfull!")
  return(bwt_file)
}

folder_path <- "BWT_120h" #folder with raw BWT data files
traj_length <- 120 #duration of BWT = number of hourly backward steps in time

traj_data <- combine_files(folder_path, traj_length)
traj_data <- prep_data(traj_data)

write.csv(traj_data, "BWT_500m_120h.csv") #export dataframe as .csv file

#<------------------------------- DATA IMPORT and MERGE ------------------------------->
#import BWT data
traj_data <- read.csv("BWT_500m_120h.csv")[,-1]
#make sure the date column is in the right format
traj_data$date <- as.POSIXct(format(traj_data$date), tz="UTC")

#import PM2.5 data
pm_data <- read.xlsx("PM_daily.xlsx")
#make sure the date column is in the right format
pm_data$date <- convertToDate(pm_data$date)
pm_data$date <- as.POSIXct(paste(as.Date(pm_data$date))) + as.difftime("07:00:00")
pm_data$date <- as.POSIXct(format(pm_data$date), tz="UTC")

#merge PM2.5 data with BWT data
data <- merge(traj_data,pm_data)
data <- data %>% arrange(date, date2) #order the data by 1) arrival date and 2) the date of BWT point back in time (only for clarity)

#add column representing the season (dry and wet)
data <- data %>% mutate(seas = case_when(
  date %within% interval("2020-03-01 07:00:00 UTC", "2020-05-01 07:00:00 UTC") ~ "Dry season",
  date %within% interval("2020-05-02 07:00:00 UTC", "2020-09-09 07:00:00 UTC") ~ "Wet season"
))

#<------------------------------- BWT ANALYSIS using the openair package ------------------------------->
#Plot the BWTs colour coded for the PM2.5 concentration
trajPlot(data,
         projection="mercator",
         pollutant = "PM",
         type="seas",
         npoints = NA,
         parameters=NULL,
         orientation = c(90,0,90),
         xlim=c(62,110),
         ylim=c(-2,30),
         lwd=2,
         main="BWTs",
         key.header = "PM2.5 (ug m-3)",
         par.settings=list(fontsize=list(text=16)))

#Plot the BWT clusters
trajCluster(data,
            projection="mercator",
            npoints = NA,
            parameters=NULL,
            orientation = c(90,0,90),
            xlim=c(62,110),
            ylim=c(-2,30),
            lwd=2,
            main="BWT clusters",
            par.settings=list(fontsize=list(text=16)))

#Plot the potential source contribution function for PM2.5 for March, April
trajLevel(selectByDate(data, start="2020-03-01",end="2020-05-01"),
          projection="mercator",
          pollutant = "PM",
          statistic="pscf",
          type="seas",
          smooth=TRUE,
          lon.inc = 1,
          lat.inc = 1,
          percentile=80,
          parameters=NULL,
          orientation = c(90,0,90),
          xlim=c(80,110),
          ylim=c(4,30),
          main="PSCF for PM2.5",
          par.settings=list(fontsize=list(text=14)),
          cols="heat")

#Plot the frequency of BWTs for March, April
trajLevel(selectByDate(data, start="01/03/2020", end="31/05/2020"),
          projection="mercator",
          pollutant = "PM",
          statistic="frequency",
          lon.inc = 0.5,
          lat.inc = 0.5,
          percentile=80,
          parameters=NULL,
          orientation = c(90,0,90),
          xlim=c(80,110),
          ylim=c(4,30),
          main="BWT frequencies",
          par.settings=list(fontsize=list(text=14)),
          cols="heat")

