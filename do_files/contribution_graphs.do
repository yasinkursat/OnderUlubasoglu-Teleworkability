* This code is to prepare the contribution of occupations for teleworkability in AU
* This .do file relies on the code used in Dingel and Neiman. Small changes made as there is no
* ILO data available for Australia. We have made the necessary conversions from ISCO code to ILO code.
* Program    : contribution_to_Tim.do
* Programmer : Yasin Kursat Onder
* Description: Contribution of occupations to Teleworkability in Australia, contribution graphs
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
*bys anzsco_2digitcode : egen a_count = count(isco_08) //one anzsco code maps more than one isco code
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
collapse (sum) employed_adjusted , by(ISCO08_Code_2digit sex year)
joinby ISCO08_Code_2digit using "$data\oes_isco2_merged_file", unmatched(both)
gen employment = employed_adjusted
bys OCC_CODE: egen tot_emp_occ = total(employment) // if missing(employment)==0 & employment!=0
gen weight = USA_OES_employment*employment/tot_emp_occ	//if missing(employment)==0 & employment!=0 //Allocates SOC's employment across ISCOs in proportion to ISCO employment shares
collapse (mean) teleworkable (firstnm) ISCO08_TITLE_2digit employment [aweight = weight], by(ISCO08_Code_2digit sex year)
replace sex = "Female" if sex == "Females"
replace sex = "Male" if sex == "Males"




destring ISCO08_Code_2digit, replace
gen emp_tel = employment*teleworkable
bys sex: egen tot_emp_tele = total(emp_tel) // if missing(employment)==0 & employment!=0
gen contribution = 100*emp_tel/tot_emp_tele
gen to_present = 0
replace to_present = 1 if ISCO08_Code_2digit == 23 | ISCO08_Code_2digit == 33 | ISCO08_Code_2digit == 13 | ISCO08_Code_2digit == 41 | ISCO08_Code_2digit == 42 | ISCO08_Code_2digit == 34 | ISCO08_Code_2digit == 24 | ISCO08_Code_2digit == 26 | ISCO08_Code_2digit == 21 | ISCO08_Code_2digit == 12


gen female_others = 100-7.371478-21.92143-22.49966-7.309149-6.895604
gen male_others = 100-9.220304-7.617999-11.68554-15.51049-6.409111
set obs `=_N+1'
replace sex = "Female" if year == .
replace ISCO08_Code_2digit = 100  if year == .
replace contribution = female_others[_n-1] if contribution == .
replace ISCO08_TITLE_2digit = "Others" if year == .

replace year = 2019 if year == .
set obs `=_N+1'
replace sex = "Male" if year == .
replace ISCO08_Code_2digit = 100  if year == .
replace contribution = male_others[_n-2] if contribution == .
replace ISCO08_TITLE_2digit = "Others" if year == .

sort contribution
splitvallabels ISCO08_TITLE_2digit
catplot ISCO08_TITLE_2digit sex [aw=contribution] if contribution > 6, ///
var1opts(label(labsize(small))) ///
var2opts(label(labsize(small)) relabel(`r(relabel)')) ///
ytitle("", size(medium)) ///
title("% Contribution of each ISCO classification" ///
, span size(small)) ///
intensity(25) ///
asyvars stack ///
bar(1, color(maroon) fintensity(inten80)) ///
bar(2, color(maroon) fintensity(inten60)) ///
bar(3, color(orange) fintensity(inten40)) ///
bar(4, color(navy) fintensity(inten60)) ///
bar(5, color(navy) fintensity(inten80)) ///
bar(6, color(black) fintensity(inten80)) ///
bar(7, color(black) fintensity(inten50)) ///
bar(8, color(gray) fintensity(inten40)) ///
legend(rows(3) stack size(small) ///
order(1 "Production and specialised" "services managers" 2 "Science and engineering" "professionals" ///
3 "Teaching" "professionals" ///
4 "Business and administration" "associate professionals" 5 "Information and" "communications technicians" ///
6 "General and" "keyboard clerks" 7 "Customer services" "clerks" ///
8 "Others") ///
symplacement(center) ///
)
capture graph export "$data\contribution_ISCO.png", as(png) replace
