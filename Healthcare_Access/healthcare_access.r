library(tidyverse)
library(strcode)
library(openxlsx)
library(tidycensus)
options(strcode = list(insert_with_shiny = FALSE,  # set options
                       char_length = 80, 
                       hash_in_sep= TRUE))


#   ____________________________________________________________________________
#   load data                                                               ####

## zip to fips
zip <- read.csv("./Healthcare_Access/www/ZIP-COUNTY-FIPS_2017-06.csv") %>% 
  rename(zip_code = ZIP, 
         county_name = COUNTYNAME,
         state_abbr = STATE,
         stcounty_fips = STCOUNTYFP) %>% 
  mutate(stcounty_fips = str_pad(stcounty_fips, 5, "left", 0),
         zip_code = str_pad(zip_code, 5, "left", 0)) %>% 
  select(-CLASSFP)

## hospitals
hospitals <- read.csv("./Healthcare_Access/www/Hospital_General_Information.csv") %>% 
  select(Hospital.Name,
         ZIP.Code,
         Hospital.Type,
         Hospital.Ownership,
         Emergency.Services,
         Hospital.overall.rating,
         Mortality.national.comparison) %>% 
  rename(hospital_name = Hospital.Name,
         zip_code = ZIP.Code,
         hospital_type = Hospital.Type,
         hospital_ownership = Hospital.Ownership,
         ER = Emergency.Services,
         hospital_rating = Hospital.overall.rating,
         hospitalMortality_vNational = Mortality.national.comparison) %>% 
  mutate(zip_code = as.character(zip_code)) %>% 
  left_join(zip, by = "zip_code", multiple = "any")

## social capital as a measure of community
community <- read.csv("./Healthcare_Access/www/social_capital_county.csv") %>% 
  select(county, county_name, pop2018, ec_county, clustering_county, 
         support_ratio_county, volunteering_rate_county, 
         civic_organizations_county) %>% 
  rename(stcounty_fips = county) %>% 
  mutate(stcounty_fips = str_pad(stcounty_fips, 5, "left", 0))

## immigrant population
immigration <- get_estimates(geography = "county", year = 2015, 
                             product = "population", vars = "B05002_013E") %>% 
  filter(variable != "DENSITY" & 
           GEOID < 57) %>% 
  separate(NAME, into = c("county_name", "state_name", "division", "region", 
                          "country"), sep = ",") %>% 
  rename(stcounty_fips = GEOID)


#   ____________________________________________________________________________
#   merge data                                                              ####

all_data <- left_join(hospitals, community, by = "stcounty_fips")
all_data <- left_join(immigration, all_data, by = "stcounty_fips")


