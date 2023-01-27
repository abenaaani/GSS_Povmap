/*
Do file to compare moments of the distribution
across census and survey...
We know that it won't work since census and survey
correspond to different periods, but this is 
how we do it
*/
set more off
clear all

*===============================================================================
//Specify team paths
*===============================================================================
version 15
if (lower("`c(username)'")=="wb378870"){
	global main      "C:\Users\WB378870\OneDrive - WBG\000.EAWVP\0.Ghana\"
	global outdata   "$main\6.SAE\1.data\"
}
if (lower("`c(username)'")=="jacqueline anum"){
	global outpath  
}
if (lower("`c(username)'")=="umuhera braimah"){
	global outdata "C:\POVMAP"
}
if (lower("`c(username)'")=="pagyekum"){
	global outdata "C:\Desktop\Povmap\"
}
if (lower("`c(username)'")=="charles k. agbenu"){
	global outdata "New Census Data\ Sae1"
}
if (lower("`c(username)'")=="abena osei-akoto"){
	global outdata   "C:\2021PHC_10%data\povmap_work"
}

global dofirst = 0

*===============================================================================
//Bring in the data for comparisons
// Data completed in 01_dataprep and 02_dataprep_survey
*===============================================================================

if (${dofirst}==1){
	use "$outdata\census_2021" if _n<10000, clear
	append using "$outdata\survey_2017", gen(survey)
	
	qui:ds
	local allvar `r(varlist)'
	
	local myvar
	foreach x of local allvar{
		capture confirm numeric variable `x'
		if (_rc==0){
			if ("`x'"!="survey") local myvar `myvar' `x'
		}
	}
	
	local myvar1
	foreach x of local allvar{
		capture confirm string variable `x'
		if (_rc==0){
			if ("`x'"!="survey") local myvar1 `myvar1' `x'
		}
	}
	
	
	groupfunction, mean(`myvar') by(survey)
	
	local dropphc work laborforce
	foreach x of local myvar{
		count if missing(`x') & survey==1
		if r(N)>0 local dropphc `dropphc' `x'
	} 
	local dropglss work laborforce
	foreach x of local myvar{
		count if missing(`x') & survey==0
		if r(N)>0 local dropglss `dropglss' `x'
	} 
	
	dis "`dropphc'"
	dis "`dropglss'"
	
	use "$outdata\census_2021", clear
		foreach x of local dropphc{
			cap drop `x'
		}
		foreach x of local myvar1{
			cap drop `x'
		}
	save "$outdata\census_2021", replace
	
	use "$outdata\survey_2017", clear
		local dont WTA_S WTA_S_HHSIZE rpcexp
		foreach x of local dropglss{
			local go: list dont & x
			if ("`go'"=="") cap drop `x'
		}
		foreach x of local myvar1{
			local go: list dont & x
			if ("`go'"=="") cap drop `x'
		}
	save "$outdata\survey_2017", replace
}
*===============================================================================
// Now compare mean and variance
*===============================================================================
use "$outdata\census_2021", clear
append using "$outdata\survey_2017", gen(survey)

	qui:ds
	local allvar `r(varlist)'
	
	local myvar
	foreach x of local allvar{
		capture confirm numeric variable `x'
		if (_rc==0){
			if ("`x'"!="survey") local myvar `myvar' `x'
		}
	}
	
	tab survey
	
replace WTA_S = 1 if survey==0
replace WTA_S_HHSIZE = hhsize if survey==0
groupfunction [aw=WTA_S_HHSIZE], by(survey) mean(`myvar')

/*
VARIABLES to CHECK!
-------------
ABENA
employed
work
laborforce
--------------
CHARLES
malep
depratio
-------------
UMU
head_ethnicity
head_marital
-------------
Samilia!!!
head_schooling
noschooling
head_educ
--------------
TONY
head_occ
head_empstat
aghouse
--------------
PATRICK
wall3
tenure3
fuel2 fuel3
toilet2
*/


