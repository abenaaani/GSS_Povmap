set more off
clear all

version 15
set matsize 8000
set seed 648743

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
	global oput  "C:\Users\WB378870\GitHub\GSS_Povmap\Data FH"
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

use "$oput\FHcensus_district.dta", clear




local vars male head_age age depratio head_ghanaian ghanaian head_ethnicity1 head_ethnicity2 head_ethnicity3 head_ethnicity4 head_ethnicity5 head_ethnicity6 head_ethnicity7 head_ethnicity8 head_ethnicity9 head_birthplace1 head_birthplace2 head_birthplace3 head_birthplace4 head_birthplace5 head_birthplace6 head_birthplace7 head_birthplace8 head_birthplace9 head_birthplace10 head_birthplace11 head_religion1 head_religion2 head_religion3 head_religion4 christian  married noschooling head_schlvl1 head_schlvl2  head_schlvl4 head_schlvl5 employed head_empstatus1 head_empstatus2 head_empstatus3 head_empstatus4 head_empstatus5 head_empstatus6 head_empstatus8 head_empstatus9 employee internetuse fixedphone pc aghouse conventional  wall2 wall3  floor2 floor3 roof1 roof2 roof3  tenure1  tenure3 rooms bedrooms lighting2 lighting3 lighting4 water_drinking1  water_drinking3 water_drinking4  water_general2 water_general3 fuel1 fuel2 fuel3  toilet1  toilet3 toilet4 toilet5 solidwaste1 solidwaste2 solidwaste3 thereg1 thereg2 thereg3 thereg4 thereg5 thereg6 thereg7 thereg8 thereg9  workpop_primary

egen workpop_primary = rsum(workpop_schlvl_4 workpop_schlvl_5)


gen D = region*100
replace D = D+district

drop district 
rename D district

merge 1:1 district using "$outdata\direct_glss7.dta"
tab region, gen(thereg)
unab hhvars: `vars'

*===============================================================================
//Create smoothed variance function
*===============================================================================
gen log_s2 = log(dir_fgt0_var)
gen logN = log(N)
gen logN2 = logN^2
gen logpop  = log(pop)
gen logpop2 = logpop^2
gen accra = region==3
//reg log_s2 logpop logpop2 i.accra#c.logN, r
//reg log_s2 logpop logpop2 i.accra##c.logN, r
gen share = log(N_hhsize/pop)
reg log_s2 share, r
local phi2 = e(rmse)^2
cap drop xb_fh
predict xb_fh, xb
predict residual,res
sum xb_fh if res!=.,d
gen exp_xb_fh = exp(xb_fh)
sum dir_fgt0_var
local sumvar = r(sum)
sum exp_xb_fh
local sump = r(sum)

//Below comes from: https://presidencia.gva.es/documents/166658342/168130165/Ejemplar+45-01.pdf/fb04aeb3-9ea6-441f-a15c-bc65e857d689?t=1557824876209#page=107
gen smoothed_var = exp_xb_fh*(`sumvar'/`sump') 
replace dir_fgt0_var = smoothed_var if (num_ea>1 & !missing(num_ea)) | (num_ea==1 & zero!=0 & zero!=1)
replace dir_fgt0 = zero if (num_ea>1 & !missing(num_ea)) | (num_ea==1 & zero!=0 & zero!=1)



fhsae dir_fgt0 `hhvars', revar(dir_fgt0_var) method(fh)


//Removal of non-significant variables
	//Removal of non-significant variables
	forval z= 0.8(-0.05)0.05{
		qui:  fhsae dir_fgt0 `hhvars', revar(dir_fgt0_var) method(fh) nonegative
		mata: bb=st_matrix("e(b)")
		mata: se=sqrt(diagonal(st_matrix("e(V)")))
		mata: zvals = bb':/se
		mata: st_matrix("min",min(abs(zvals)))
		local zv = (-min[1,1])
		if (2*normal(`zv')<`z') exit	
		foreach x of varlist `hhvars'{
			local hhvars1
			qui: fhsae dir_fgt0 `hhvars', revar(dir_fgt0_var) method(fh) nonegative
			qui: test `x' 
			if (r(p)>`z'){
				local hhvars1
				foreach yy of local hhvars{
					if ("`yy'"=="`x'") dis ""
					else local hhvars1 `hhvars1' `yy'
				}
				}
			else local hhvars1 `hhvars'
			local hhvars `hhvars1'		
		}
	}	

	
	//Global with non-significant variables removed
	global postsign `hhvars'
	
	//Final model without non-significant variables no funciona
	fhsae dir_fgt0 ${postsign}, revar(dir_fgt0_var) method(fh)
	
	//Check VIF
	reg dir_fgt0 $postsign, r
	gen touse = e(sample)
	gen weight = 1
	mata: ds = _f_stepvif("$postsign","weight",5,"touse") 
	
	//ver abajo
	global postvif `vifvar'
	
	local hhvars $postvif
	
	//One final removal of non-significant covariates
	forval z= 0.8(-0.05)0.0001{
		qui:fhsae dir_fgt0 `hhvars', revar(dir_fgt0_var) method(fh) precision(1e-10)
		mata: bb=st_matrix("e(b)")
		mata: se=sqrt(diagonal(st_matrix("e(V)")))
		mata: zvals = bb':/se
		mata: st_matrix("min",min(abs(zvals)))
		local zv = (-min[1,1])
		if (2*normal(`zv')>=`z'){
			foreach x of varlist `hhvars'{
				local hhvars1
				qui: fhsae dir_fgt0 `hhvars', revar(dir_fgt0_var) method(fh) precision(1e-10)
				qui: test `x' 
				if (r(p)>`z'){
					local hhvars1
					foreach yy of local hhvars{
						if ("`yy'"=="`x'") dis ""
						else local hhvars1 `hhvars1' `yy'
					}
				}
				else local hhvars1 `hhvars'
				local hhvars `hhvars1'		
			}
		}
	}
	
	fhsae dir_fgt0 `hhvars', revar(dir_fgt0_var) method(reml) precision(1e-10)
	local remove head_religion3
	local hhvars: list hhvars - remove
	global last `hhvars'
//*********************************************************************************************//

	//Obtain SAE-FH-estimates	
	fhsae dir_fgt0 workpop_primary $last, revar(dir_fgt0_var) method(reml) fh(fh_fgt0) ///
	fhse(fh_fgt0_se) fhcv(fh_fgt0_cv) gamma(fh_fgt0_gamma) out noneg precision(1e-13)
	
	
	//Check normal errors
	predict xb
	gen u_d = fh_fgt0 - xb
		lab var u_d "FH area effects"
	
	histogram u_d
	
	gen e_d = dir_fgt0 - fh_fgt0
		lab var e_d "FH errors"
	
	histogram e_d
		

keep region district fh_fgt0 fh_fgt0_se
save "$outdata\FH_sae_poverty.dta", replace