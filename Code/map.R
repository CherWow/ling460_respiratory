# Cheryl Hornung
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
# Install ggplot
library(ggplot2)
# Install sp
library(sp)
# Install rgdal
library(rgdal)
# Install broom
library(broom)
library(dplyr)
library(ggmap)
library(sf)
library(terra)
library(maps)
library(mapproj)
library(sp)
mortSP = st_read("Data/output/mortality2021SP.shp")

#get helper
countyHelp = read.csv("Data/output/countyHelp.csv")

#merge helper with mort
cMortcsv = left_join(x = csvMort, y = countyHelp, by = "FIPS")

# #separate county from state
# fips.codes = csvMort %>%
#   separate(County, c("subregion", "county"), " ")

# # get rid of subregion
# cMortcsv = subset(fips.codes, select = -c(county))

# lowercase
cMortcsv$subregion = tolower(cMortcsv$subregion)
cMortcsv$region = tolower(cMortcsv$region)

# import county lines
mapData = map_data("county")

#join data
mortMap = left_join(mapData, cMortcsv, by= c("region"="region", "subregion" = "subregion"), multiple = "all")
colnames(mortMap)[11] = "Rate"
mortMap = mortMap %>% filter(!is.na(mortMap$County))

# trying to fix the "discrete continuous data" error below

# RateBlanks = ifelse(mortMap$Rate == "Unreliable", "", mortMap$Rate)
# mortMap$Rate = RateBlanks


ggplot() +
  geom_polygon(data = mortMap, aes(x = long, y = lat, group = group, fill = Death), color = "black") +
  scale_fill_gradient(name = "Mortality Totals", low = "green", high = "red") +
  coord_map() +
  theme_void()

ggplot() +
  geom_polygon(data = mortMap, aes(x = long, y = lat, group = group, fill = Rate), color = "black") +
  scale_fill_gradient(name = "Mortality Rate", low = "green", high = "red") +
  coord_map() +
  theme_void()

# 
# ggplot(mortMap, aes(x = long, y = lat, group = group)) +
#   geom_polygon(aes(fill = Crude.Rate), color = "black") +
#   scale_fill_gradient(name = "Mortality rate", low = "green", high = "red") 
# # +
  # coord_map() +
  # theme_void()


