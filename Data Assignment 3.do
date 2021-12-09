*log file open
log using data_assignment_3_log, replace

********************************************************************
*Start off, cd into folder
********************************************************************
clear
* get into my directly
cd "C:\Users\Brayden Bulloch\OneDrive - BYU\Econ 388\Data Assignment 3"
*make sure to save each file as csv


********************************************************************
*Population Data
********************************************************************
import delimited using "census-pop-by-county - copy.csv", clear

*give v1 v2 and v3 new names 
rename v1 geoID
rename v2 county
rename v4 population
rename v6 year
keep geoID county population year

drop if _n<3
destring year, replace force
keep if year==2019



gen fips = substr(geoID, 10, 5)
destring fips, replace
destring population, replace

keep geoID county population fips

save "census-pop-by-county.dta", replace


********************************************************************
*NY Times Case/Death Data
********************************************************************
clear

* import the data from the NY Times site
import delimited using "CovidDeaths.csv"
keep geoid county state cases deaths
gen fips = substr(geoid,5,5)
drop geoid
destring fips, replace
collapse (sum) cases deaths (min) fips, by (county state)
*collapsing data will create a new dataset that contains summary stats of orig data
save "CovidDeaths.dta", replace



********************************************************************
*HPI Data
********************************************************************
clear

import delimited using "HPI_with_3_digit_zip_code.csv"

rename indexnsa HPI
rename ïthreedigitzip threedigitzip
destring threedigitzip, replace force
destring year, replace force
keep if year==2021
destring HPI, replace
collapse HPI, by(year threedigitzip)
save "HPI_with_3_digit_zip_code.csv.dta", replace


********************************************************************
*Zip County Cross Walk
********************************************************************
clear

import delimited using "crosswalk.csv", clear
keep ïzip county
rename ïzip zipcode
tostring(zipcode), gen(zipcode1)
drop zipcode
gen threedigitzip = substr(zipcode1,1,3)
drop zipcode1
destring threedigitzip, replace

save "crosswalk.dta", replace




********************************************************************
*Start merging
********************************************************************
use "census-pop-by-county.dta", clear
merge 1:1 fips using "CovidDeaths.dta"
keep if _m==3
drop _m
save "Population Covid Deaths.dta",replace

clear
*we will be merging threedigitzip
use "HPI_with_3_digit_zip_code.csv.dta", clear
merge 1:m threedigitzip using "crosswalk.dta"
keep if _m==3
drop _m
collapse HPI, by(county)
rename county fips
save "Zip HPI.dta", replace

merge 1:1 fips using "Population Covid Deaths.dta"
keep if _m==3
drop _m

gen mortalityrate = (deaths/population)*100



********************************************************************
*Actual Analysis
********************************************************************
reg HPI mortalityrate
*make sure to add dummy var
encode(state), gen(statenum)
reg HPI mortalityrate i.statenum
gen loghpi = log(HPI)

reg loghpi mortalityrate i.statenum
*run regression for logphi mortalityrate i.statenum
log close
