
clear
set more off

use census47810,clear
append using census123
append using census569

keep if relationship==1
local vars aghouse hhsize head_male malep head_age age_avg head_ghanaian ghanaianp head_ethnicity1 - head_ethnicity10 ///
		head_birthplace1 - head_birthplace11 head_religion1 - head_religion4 christianp head_maritalstatus1 - head_maritalstatus6 marriedp ///
		head_schlvl1 - head_schlvl3 noschoolingp employedp /*head_occ1 - head_occ11 */ head_empstatus1 - head_empstatus9 employeep ///
		mobileown internetuse /*birth12mo surviverate */ fixedphone pc  conventional wall1 - wall3 floor1 - floor3 roof1 - roof4 tenure1 - tenure3 rooms bedrooms ///
		lighting1 - lighting4 water_drinking1 - water_drinking4 water_general1 - water_general3 fuel1 - fuel4 toilet1 - toilet5 solidwaste1 - solidwaste4 
keep region district subdist distype ea urban `vars'

//merge m:1 region district ea using "$cleandata\areamean"
//drop _me
gen metro=(distype*100) + subdist

replace region = region + 10
//g long id = region*100000 + district*1000 + ea
g long id = (region*100000000) + (district*1000000) + (metro*1000) + ea

order id region district ea urban, first
mean urban rooms bedrooms aghouse hhsize - solidwaste4
saveold census_nom,replace
use census_nom,clear
