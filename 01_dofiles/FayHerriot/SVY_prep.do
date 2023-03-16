//do file to prepare SURVEY data for poverty mapping
*same as collapse
*ssc install groupfunction
**************************************
*This dofile prepares data from GLSS7 for
* small area estimation
*****************************************
clear all
set more off

version 14

*===============================================================================
//Specify team paths
*===============================================================================


if (lower("`c(username)'")=="tony"){
	global dpath "C:\Users\Tony\F-paper Dropbox\Anthony Krakah\PC\Desktop\POVERTY_MAPS\STATA_10%SAMPLE\" 
}
if (lower("`c(username)'")=="wb378870"){
	global dpath "C:\Users\WB378870\OneDrive - WBG\000.EAWVP\0.Ghana\0.Data\10.Census_2021"
} 
 
//use "$dpath\defactopopn_10%_20221011d.dta" /*if _n<1000*/, clear
if (lower("`c(username)'")=="tony"){
	global glss "C:\Users\Tony\F-paper Dropbox\Anthony Krakah\PC\Desktop\OFFICE DESKTOP OLD\GLSS7\glss7data\data\glss7stata\g7PartA_1"	
	global glssagg "C:\Users\Tony\F-paper Dropbox\Anthony Krakah\PC\Desktop\OFFICE DESKTOP OLD\GLSS7\glss7data\data\glss7stata\g7aggregates_1"	
	global outdata "$glss"
}
if (lower("`c(username)'")=="wb378870"){
	global main      "C:\Users\WB378870\OneDrive - WBG\000.EAWVP\0.Ghana\"
	global ghanadata "$main\0.Data\0.GLSS\GLSS-VII from GSS\"
	global glss      "$ghanadata\g7stata\g7PartA\"
	global glssagg   "$ghanadata\g7stata\g7aggregates\"
	global outdata   "$main\6.SAE\1.data\"
} 
if (lower("`c(username)'")=="abena osei-akoto"){
	global glss "C:\GLSS7\g7stata"
	global glssagg "C:\GLSS7\g7stata\agg"
	global outdata   "C:\2021PHC_10%data\povmap_work"
}
if (lower("`c(username)'")=="pagyekum"){
	global glss "C:\Desktop\Povmap\glss7stata\g7PartA_1\"
	global glssagg "C:\Desktop\Povmap\glss7stata\g7aggregates_1"
	global outdata "C:\Desktop\Povmap"
}
if (lower("`c(username)'")=="charles k. agbenu"){
	global glss "C:\Users\CHARLES K. AGBENU\Documents\glss7stata\g7PartA_1"
	global glssagg "C:\Users\CHARLES K. AGBENU\Documents\glss7stata\g7aggregates_1"
	global outdata "C:\Users\CHARLES K. AGBENU\Documents\Pov Output\GLSS output"
}
if (lower("`c(username)'")=="umuhera braimah"){
    global glss "C:\POVMAP\glss7stata\g7PartA_1\"
    global glssagg   "c:\POVMAP\glss7stata\g7aggregates\"
    global outdata "C:\POVMAP"
}

use "$outdata\survey_2017.dta",clear

	egen strata = group(region urban)
	svyset clust [pw=WTA_S_HHSIZE], strata(strata)
	gen fgt0 = (welfare < pl_abs) if !missing(welfare)
	
preserve
groupfunction [aw=WTA_S_HHSIZE], mean(fgt0) rawsum(WTA_S_HHSIZE) by(district clust)

groupfunction [aw=WTA_S_HHSIZE], mean(fgt0) count(clust) by(district)
restore

svy:proportion fgt0, over(district)

mata: fgt0 = st_matrix("e(b)")
mata: fgt0 = fgt0[(cols(fgt0)/2+1)..cols(fgt0)]'
mata: fgt0_var = st_matrix("e(V)")
mata: fgt0_var = diagonal(fgt0_var)[(cols(fgt0_var)/2+1)..cols(fgt0_var)]

groupfunction [aw=WTA_S_HHSIZE], mean(fgt0) by(region district)

sort district
getmata dir_fgt0 = fgt0 dir_fgt0_var = fgt0_var

replace dir_fgt0_var = . if dir_fgt0_var==0
replace dir_fgt0 = . if missing(dir_fgt0_var)

save "$outdata\direct_glss7.dta", replace
