* This code is to prepare the contribution of occupations for teleworkability in AU
* This .do file relies on the code used in Dingel and Neiman. Small changes made as there is no
* ILO data available for Australia. We have made the necessary conversions from ISCO code to ILO code.
* Program    : contribution_to_Tim.do
* Programmer : Yasin Kursat Onder
* Description: Contribution of occupations to Teleworkability in Australia
* Date       : 
* Updated	 : 
* Data       : 
clear all
set maxvar 32767
set more off
set matsize 10000



********************************************************************
global data="C:\Users\c\Dropbox\cureshot\Deakin\COVID-19"
*******************************************************************

clear all
use "$data\employed_2digit.dta" 
destring anzsco_2digit, replace
gen date = monthly(midquartermonth,"MY")
clonevar date1 = date
format date %tm
gen day=dofm(date)
gen year=yofd(day)
format year %ty
keep if year == 2019
ren anzsco_2digit anzsco_2digitcode
sort anzsco_2digitcode
ren stateandterritorysttasgs2011 state
collapse (sum) employedtotal000 , by(year anzsco_2digitcode state sex)
joinby anzsco_2digit using "$data\conversion.dta", unmatched(both)

bys anzsco_2digitcode : egen a_count = count(anzsco_2digitcode) //one anzsco code maps more than one isco code
destring isco_08, replace
gen employed_adjusted = employedtotal000/a_count //if a_count > 0 & !mi(a_count)
tempvar tv1 tv2
bys year: egen `tv1' = total(employed_adjusted) if _merge == 1
by  year: egen `tv2' = total(employed_adjusted)
gen unallocated_employment_share = `tv1'/`tv2'
drop `tv1' `tv2'
drop _merge

tostring isco_08, replace
ren isco_08 ISCO08_Code_2digit
drop if ISCO08_Code_2digit == "01" | ISCO08_Code_2digit ==  "02" | ISCO08_Code_2digit == "03" // Drop military occupations
sort ISCO08_Code_2digit
collapse (sum) employed_adjusted , by(ISCO08_Code_2digit state sex year)
joinby ISCO08_Code_2digit using "$data\oes_isco2_merged_file", unmatched(both)

gen employment = employed_adjusted
bys OCC_CODE: egen tot_emp_occ = total(employment) // if missing(employment)==0 & employment!=0
gen weight = USA_OES_employment*employment/tot_emp_occ	//if missing(employment)==0 & employment!=0 //Allocates SOC's employment across ISCOs in proportion to ISCO employment shares
collapse (mean) teleworkable (firstnm) ISCO08_TITLE_2digit employment [aweight = weight], by(ISCO08_Code_2digit state sex year)
replace sex = "Female" if sex == "Females"
replace sex = "Male" if sex == "Males"



collapse (mean) teleworkable [pweight = employment ], by(state sex year)

splitvallabels state
catplot sex state [aw=teleworkable] , ///
var1opts(label(labsize(medium))) ///
var2opts(label(labsize(medium)) relabel(`r(relabel)')) ///
ytitle("Index", size(medium)) ///
title("Teleworkability by Gender and State" ///
, span size(medium)) ///
blabel(bar, format(%4.2f) size(vsmall)) ///
asyvars ///
bar(1, color(red) fintensity(inten40)) ///
bar(2, color(blue) fintensity(inten40)) ///
intensity(25) ///
legend(rows(1) stack size(small) ///
order(1 "Female" 2 "Male" ) ///
symplacement(center) ///
)
capture graph save "$data\gender_state",  replace
capture graph export "$data\gender_state.png", as(png) replace

