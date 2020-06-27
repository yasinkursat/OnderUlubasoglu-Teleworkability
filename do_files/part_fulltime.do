* This code is to prepare the contribution of occupations for teleworkability in AU
* This .do file relies on the code used in Dingel and Neiman. Small changes made as there is no
* ILO data available for Australia. We have made the necessary conversions from ISCO code to ILO code and enriched it with age and some other characteristics.
* Program    : contribution_to_Tim.do
* Programmer : Yasin Kursat Onder
* Description: Contribution of occupations to Teleworkability in Australia, part-time full time analysis
* Date       : 
* Updated	 : 
* Data       : 
clear all
set maxvar 32767
set more off
set matsize 10000
clear all
set maxvar 32767
set more off
set matsize 10000


********************************************************************
global data="C:\Users\c\Dropbox\cureshot\Deakin\COVID-19"
*******************************************************************

clear all
use "$data\employed_part_fulltime.dta" 
destring anzsco_2digit, replace
gen date = monthly(midquartermonth,"MY")
clonevar date1 = date
format date %tm
gen day=dofm(date)
gen year=yofd(day)
format year %ty
egen maxyear = max(year)
keep if year == 2019
sort anzsco_2digitcode
gen total_employment = employedfulltime000 + employedparttime000
collapse (sum) employedfulltime000 employedparttime000 total_employment, by(anzsco_2digitcode year sex age)
joinby anzsco_2digit using "$data\conversion.dta", unmatched(both)
bys anzsco_2digitcode: egen a_count = count(anzsco_2digitcode) //one anzsco code maps more than one isco code
destring isco_08, replace
gen employed_full = employedfulltime000/a_count //if a_count > 0 & !mi(a_count)
gen employed_part = employedparttime000/a_count //if a_count > 0 & !mi(a_count)
gen employed_total = total_employment/a_count //if a_count > 0 & !mi(a_count)

tempvar tv1 tv2
bys year: egen `tv1' = total(total_employment) if _merge == 1
by  year: egen `tv2' = total(total_employment)
gen unallocated_employment_share = `tv1'/`tv2'
drop `tv1' `tv2'
drop _merge
tostring isco_08, replace
ren isco_08 ISCO08_Code_2digit
drop if ISCO08_Code_2digit == "01" | ISCO08_Code_2digit ==  "02" | ISCO08_Code_2digit == "03" // Drop military occupations
sort ISCO08_Code_2digit
*bys ISCO08_Code_2digit state sex: egen std_employment = sd(employed_adjusted)
collapse (sum) employed_full employed_part employed_total, by(ISCO08_Code_2digit sex age year)
joinby ISCO08_Code_2digit using "$data\oes_isco2_merged_file", unmatched(both)
gen fullemployment = employed_full
gen partemployment = employed_part
gen totalemployment = employed_total
bys OCC_CODE: egen full_emp_occ = total(fullemployment) // if missing(employment)==0 & employment!=0
gen weight_full = USA_OES_employment*fullemployment/full_emp_occ	//if missing(employment)==0 & employment!=0 //Allocates SOC's employment across ISCOs in proportion to ISCO employment shares
bys OCC_CODE: egen part_emp_occ = total(partemployment) // if missing(employment)==0 & employment!=0
gen weight_part = USA_OES_employment*partemployment/part_emp_occ	//if missing(employment)==0 & employment!=0 //Allocates SOC's employment across ISCOs in proportion to ISCO employment shares

bys OCC_CODE: egen tot_emp_occ = total(totalemployment) // if missing(employment)==0 & employment!=0
gen weight = USA_OES_employment*totalemployment/tot_emp_occ	//if missing(employment)==0 & employment!=0 //Allocates SOC's employment across ISCOs in proportion to ISCO employment shares



tempfile fullpart_data
save `fullpart_data'

use `fullpart_data', clear

collapse (mean) teleworkable totalemployment [aweight = weight], by(ISCO08_Code_2digit sex age)
collapse (mean) teleworkable [aweight = totalemployment ], by(sex age)

replace sex = "Female" if sex == "Females"
replace sex = "Male" if sex == "Males"

splitvallabels age
catplot sex age [aw=teleworkable] , ///
var1opts(label(labsize(medium))) ///
var2opts(label(labsize(medium)) relabel(`r(relabel)')) ///
ytitle("Index", size(medium)) ///
title("Teleworkability by Age for Total Employment" ///
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
capture graph save "$data\age_gender_total",  replace
capture graph export "$data\age_gender_total.png", as(png) replace
save "$data\teleworkability_total.dta", replace

use `fullpart_data', clear 
collapse (mean) teleworkable fullemployment [aweight = weight_full], by(ISCO08_Code_2digit sex age)
collapse (mean) teleworkable [aweight = fullemployment ], by(sex age)
splitvallabels age
catplot sex age [aw=teleworkable] , ///
var1opts(label(labsize(medium))) ///
var2opts(label(labsize(medium)) relabel(`r(relabel)')) ///
ytitle("Index", size(medium)) ///
title("Teleworkability by Age for Full-Time Employed" ///
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
capture graph save "$data\age_gender_full",  replace
capture graph export "$data\age_gender_full.png", as(png) replace
save "$data\teleworkability_full.dta", replace

use `fullpart_data', clear 
collapse (mean) teleworkable partemployment [aweight = weight_part], by(ISCO08_Code_2digit sex age)
collapse (mean) teleworkable [aweight = partemployment ], by(sex age)
splitvallabels age
catplot sex age [aw=teleworkable] , ///
var1opts(label(labsize(medium))) ///
var2opts(label(labsize(medium)) relabel(`r(relabel)')) ///
ytitle("Index", size(medium)) ///
title("Teleworkability by Age for Part-Time Employed" ///
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
capture graph save "$data\age_gender_parttime",  replace
capture graph export "$data\age_gender_parttime.png", as(png) replace
save "$data\teleworkability_part.dta", replace
