#### Cheryl Hornung
#### 
####

##########################                      
####  Load libraries  ####
##########################

# Importing sf
library(sf)
# Importing tidyverse
library(tidyverse)
# Importing rmapshaper
library(rmapshaper)
# Importing readxl
library(readxl)
# Importing janitor
library(janitor)
# Install ggpubr
library(ggpubr)



########################      
####  Read in data  ####
########################   

################
# SPATIAL DATA #
################

# Read in US States spatial data layer
states.fips <- st_read("Data/USstates/US_states.shp")


# Read in US Counties spatial data layer
counties.fips <- st_read("Data/UScounties/UScounties.shp")

# remove leading 0's from FIPS
FIPS_new <- str_replace(counties.fips$FIPS, "^0+", "")

# Replace FIPS with FIPS_new
counties.fips$FIPS <- FIPS_new

#######################
# AQI DATA #
#######################
# Resource: https://aqs.epa.gov/aqsweb/airdata/download_files.html#Annual
# understanding the findings https://aqs.epa.gov/aqsweb/airdata/FileFormats.html

# Read in annual AQI (2020) by county
aqi_annual_county <- read.csv("Data/pollutionData/annual_aqi_by_county_2020.csv")



################
# SMOKING DATA #
################

# Read in Mortality Rate Report by State 2014-2018
cig_use <- read_excel("Data/respiratoryData/cig_use.xlsx")

# Join/merge spatial and table data
cig_use.sp <- merge(states.fips, 
                    cig_use,
                    by.x = "STATE_NAME",
                    by.y = "LocationDesc",
                    all.x = TRUE)


#######################
# MORTALITY DATA #
#######################
# CDC data URL https://wonder.cdc.gov/controller/datarequest/D158;jsessionid=D2E693D85E27FAF498B3CA3E757A
# more references https://wonder.cdc.gov/wonder/help/ucd-expanded.html
# additional resources under Data/notes/CDCrespiratoryNotes.txt

# Read in Mortality Rate Report by County 2021
mort21 = read.delim("Data/respiratoryData/Death2021.txt", header = TRUE, sep = "\t", dec = ".")
# delete "notes" column
mort21 = subset(mort21, select = -c(Notes))
# renaming fips
colnames(mort21)[2] = "FIPS"


################################
# MEDIAN HOUSEHOLD INCOME DATA #
################################

# Read in median household income by county
med_income.county <- read.csv("Data/IncomeData/medinc_county.csv")


######################
# POVERTY RATE DATA #
######################

# Read in Poverty by county 2015-2020
poverty.fips.county <- read_excel("Data/IncomeData/poverty_county.xlsx")



########################
####  Process data  ####
######################## 

################
# SPATIAL DATA #
################

# Make spatial data layer valid (just a good habit using sf objects)
states.fips <- st_make_valid(states.fips)


# Make spatial data layer valid (just a good habit using sf objects)
counties.fips <- st_make_valid(counties.fips)


##############################
# DEATH COUNTY DATA #
##############################


# Join/merge spatial and table data
mort21.sp <- merge(counties.fips, 
                   mort21, 
                   by.x = "FIPS",
                   by.y = "FIPS",
                   all.x = TRUE)
# removing NAs
mort21 %>% drop_na()

#############################
# AQI DATA #
#############################

# Join/merge spatial and table data
AQI.sp <- merge(counties.fips, 
                aqi_annual_county,
                by.x = "NAME",
                by.y = "County",
                all.x = TRUE)
# remove NAs
AQI.sp %>% drop_na()
