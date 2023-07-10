set more off
clear all

global dpath "C:\Users\WB378870\OneDrive - WBG\000.EAWVP\0.Ghana\6.SAE\1.data\"
global oput  "C:\Users\WB378870\GitHub\GSS_Povmap\Data FH"

*===============================================================================
// Import centroids...
*===============================================================================
import delimited using "$dpath\district_centroids.csv", clear

keep district dist_code x y
rename district distname 
rename dist_code district
rename y latitude
rename x longitude

tempfile centroids
save `centroids'


*===============================================================================
//Census Pop
*===============================================================================
use "$oput\FHcensus_district.dta", clear
keep pop district region

gen D = region*100
replace D = D+district

drop district 
rename D district

tempfile pops
save `pops'

*===============================================================================
// Direct estimates 
*===============================================================================
use "$dpath/direct_glss7_region.dta", clear
gen u_ci = fgt0+invnormal(0.975)*sqrt(dir_fgt0_var)
gen l_ci = fgt0+invnormal(0.025)*sqrt(dir_fgt0_var)

keep region fgt0 l_ci u_ci
list
rename fgt0 direct_fgt0

tempfile direct
save `direct'

*===============================================================================
//Fay Herriot Estimates
*===============================================================================
use "$dpath/FH_sae_poverty.dta", clear
merge m:1 region using `direct'
	drop if _m==2
	drop _m
merge 1:1 region district using `pops'
	drop if _m==2
	drop _m
	
merge 1:1 district using `centroids'
	drop if _m==2
	drop _m
	
merge 1:1 district using "$outdata\direct_glss7.dta", keepusing( dir_fgt0 dir_fgt0_var)
	drop if _m==2
	drop _m
	
//See the improvement in precision
gen se=sqrt( dir_fgt0_var)
twoway (scatter fh_fgt0_se se ) (line se se), graphregion(color(white)) ytitle(Fay Herriot (rmse)) xtitle(Direct estimate (SE)) legend(off)


	
preserve
	groupfunction [aw=pop], mean(fh_fgt0 direct_fgt0 *_ci) by(region)

	graph dot (asis) fh_fgt0 u_ci l_ci, over(region) marker(2, mcolor(red) msymbol(diamond)) marker(3, mcolor(red) msymbol(diamond)) graphregion(color(white)) legend(order(1 "Poverty headcount from Fay Herriot" 2 "Direct estimate CI (95%)") cols(1)) 
restore

*===============================================================================
// HOtspots
*===============================================================================
hotspot fh_fgt0, ycoord(latitude) xcoord(longitude) indiff(0) neigh(10) radius(600)

gen hotspot = ""
rename goS_ value
	replace hotspot = "Not significant" if value==   0 
	replace hotspot = "Cold-spot (99%)" if inrange(value,  -1,-.99) 
	replace hotspot = "Cold-spot (95%)" if inrange(value,-.96,-.94) 
	replace hotspot = "Cold-spot (90%)" if inrange(value,-.91,-.89) 
	replace hotspot = "Hot-spot (99%)"  if inrange(value, .98,   1) 
	replace hotspot = "Hot-spot (95%)"  if inrange(value, .94, .96) 
	replace hotspot = "Hot-spot (90%)"  if inrange(value, .89, .91) 

*===============================================================================
//Local Moran's I
*===============================================================================
localmoran fh_fgt0, ycoord(latitude) xcoord(longitude) indiff(0) neigh(10) radius(600)
rename outlier_fh_fgt0 localmoran
*===============================================================================
// Prep data for Tableau
*===============================================================================
xtile q10 = fh_fgt0, nq(10)
gen range_Q10 = ""
local last = 0
	forval q=1/10{
		sum fh_fgt0 if q10==`q'
		local min = round(`=100*`r(min)'',0.1)
		local min = trim("`: dis %10.1f `min''")
		local max = round(`=100*`r(max)'',0.1)
		local max = trim("`: dis %10.1f `max''")

		replace range_Q10 = "`min' - `max'" if  q10==`q'
	}	



replace range_Q10 = "NULL" if range_Q10 ==""


export delimited using "$dpath\fh_sae_gha.csv", replace

*===============================================================================
// Table for document with poverty for all 216 locations
*===============================================================================
sort region distname
keep region distname pop fh_fgt0  fh_fgt0_se
gen numpoor = pop*fh_fgt0

order region distname pop fh_fgt0 fh_fgt0_se numpoor

export excel using "$dpath\povertyTable.xlsx", sheet(tab_stata) first(variable) sheetreplace