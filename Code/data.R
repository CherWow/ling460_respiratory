#### Cheryl Hornung
#### 
####

##########################                      
####  Load libraries  ####
##########################
# install
install.packages("rgdal")


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
# rdgal
library(rgdal)




############################# 
####  Read/Process data  ####
#############################
#############################



################
# SPATIAL DATA #
################

# Read in US States spatial data layer
states.fips <- st_read("Data/USstates/US_states.shp")

# Read in US Counties spatial data layer
counties.fips <- st_read("Data/UScounties/UScounties.shp")

# remove leading 0's from FIPS
counties.fips$FIPS <- str_replace(counties.fips$FIPS, "^0+", "")

#rename header county spatial data
names(counties.fips)[names(counties.fips) == "NAME"] <- "subregion"
names(counties.fips)[names(counties.fips) == "STATE_NAME"] <- "region"

#create new df to help clean data
countyhelper = subset(counties.fips, select = c("subregion", "region","FIPS"))

#export df
write_csv(countyhelper, "Data/output/countyHelp.csv")

# Make spatial data layer valid (just a good habit using sf objects)
states.fips <- st_make_valid(states.fips)

# Make spatial data layer valid (just a good habit using sf objects)
counties.fips <- st_make_valid(counties.fips)










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
cig_use.sp %>% filter(!is.na(cig_use.sp$Data_Value))










#######################
# AQI DATA #
#######################
# Resource: https://aqs.epa.gov/aqsweb/airdata/download_files.html#Annual
# understanding the findings https://aqs.epa.gov/aqsweb/airdata/FileFormats.html

# Read in annual AQI (2020) by county
aqi_annual_county <- read.csv("Data/pollutionData/annual_aqi_by_county_2020.csv")

# rename headers
names(aqi_annual_county)[names(aqi_annual_county) == "County"] <- "subregion"
names(aqi_annual_county)[names(aqi_annual_county) == "State"] <- "region"

# Join/merge spatial and table data
AQI.sp <- merge(aqi_annual_county,
                counties.fips, 
                by.x = c("subregion", "region"),
                by.y = c("subregion", "region"),
                all.x = TRUE)

# filtering out non-spatial data
AQI.sp = AQI.sp %>% filter(!is.na(AQI.sp$FIPS))








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

# filter out NA values
mort21 = mort21 %>% filter(!is.na(mort21$FIPS))


# Merge AQI and mortality rates due to respiratory disease
mortAQI.sp = merge(AQI.sp,
                   mort21,
                   by.x = "FIPS",
                   by.y = "FIPS",
                   all.x = TRUE)

# filter out NA values
mortAQI.sp = mortAQI.sp %>% filter(!is.na(mortAQI.sp$Deaths))

# Join/merge spatial and table data
mort21.sp <- merge(counties.fips, 
                   mort21, 
                   by.x = "FIPS",
                   by.y = "FIPS",
                   all.x = TRUE)
# remove NAs
mort21.sp = mort21.sp %>% filter(!is.na(mort21.sp$Deaths))











######## INCOME ###############
###############################
###############################



################################
# MEDIAN HOUSEHOLD INCOME DATA #
################################

# Read in median household income by county
medincome <- read.csv("Data/IncomeData/medinc_county.csv")

# Join/merge spatial and table data
medinc.sp <- merge(counties.fips, 
                   medincome, 
                   by.x = "FIPS",
                   by.y = "FIPS",
                   all.x = TRUE)

# filter out NAs
medinc.sp = medinc.sp %>% filter(!is.na(medinc.sp$Value..Dollars))

# merge income data with aqi
INC_AQI = merge(AQI.sp,
                   medincome,
                   by.x = "FIPS",
                   by.y = "FIPS")


#######################
# POVERTY COUNTY DATA #
#######################

# Read in Poverty by county 2015-2020
poverty <- read_excel("Data/IncomeData/poverty_county.xlsx")

# Changing column name for third column to something more simple
colnames(poverty)[3] <- "Percent_Below_Poverty"

#rename column to FIPS
names(poverty)[names(poverty) == "countyFIPS"] = "FIPS"

# Join/merge spatial and table data
poverty.sp <- merge(counties.fips, 
                    poverty, 
                    by.x = "FIPS",
                    by.y = "FIPS",
                    all.x = TRUE)
poverty.sp = poverty.sp %>% filter(!is.na(poverty.sp$Percent_Below_Poverty))

# merge poverty with aqi and income
INC_AQI.sp = merge(INC_AQI,
                poverty,
                by.x = "FIPS",
                by.y = "FIPS")

# merge income data with mortality and aqi
INCmortAQI.sp = merge(INC_AQI,
                   mort21,
                   by.x = "FIPS",
                   by.y = "FIPS")











##############################################
# merge aqi mortality without spatial data #
##############################################

INCmortAQI = data.frame(INCmortAQI.sp)
INCmortAQI <- INCmortAQI[, -which(names(INCmortAQI) == "geometry")]


############################# 
####  Write out results  ####
############################# 

## mort21 csv
write_csv(mort21,
          "Data/output/mortality2021.csv",
          append = FALSE)

# mort21 spatial
st_write(mort21.sp, "Data/output/mortality2021SP.shp", append = FALSE)

#poverty csv
write_csv(poverty, "Data/output/poverty.csv", append = FALSE)

# poverty spatial
st_write(poverty.sp, "Data/output/poverty.shp", append = FALSE)

# AQI csv
write_csv(aqi_annual_county, "Data/output/aqi.csv", append = FALSE)

# AQI spatial
st_write(AQI.sp, "Data/output/aqiSP.shp", append = FALSE)

# median income csv
write_csv(medincome,"Data/output/medincome.csv", append = FALSE)

# median income spatial 
st_write(medinc.sp, "Data/output/medincomeSP.shp", append = FALSE)

#write out mortAQI.sp (merged data with spatial data)
st_write(mortAQI.sp, "Data/output/mortality_AQI_MERGED.shp", append = FALSE)

#write out income aqi
st_write(INC_AQI, "Data/output/income_aqi.shp", append = FALSE)

#write out income mortality and aqi
st_write(INCmortAQI, "Data/output/income_mortality_aqi.shp", append = FALSE)
