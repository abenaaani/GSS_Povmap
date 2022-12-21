set more off
clear all
//do file to prepare census data for poverty mapping
* same as collapse
*ssc install groupfunction
**************************************
*This dofile prepares data from the census for
* small area estimation
*****************************************
set more off
clear all

if (lower("`c(username)'")=="wb378870"){
	global dpath "C:\Users\WB378870\OneDrive - WBG\000.EAWVP\0.Ghana\0.Data\9.Census_2010"
} 
use "$dpath\defactopopn_10%_20221011d.dta" /*if _n<1000*/, clear

	//We keep only households
	keep if restype==1
	
	//Data is at the individual level; unique at the nqid pid
	
	//Generate head sex
	egen headsex=max(((a11d==2) & a11c==1)), by(nqid)
		lab var headsex "Female head of household"
		
	//Generate head age
	egen headage=max(((a11c==1)*p02)), by(nqid)
		lab var headsex "Age of head of household"
	
	//Generate nationality of head
	egen head_nat = max((a11c==1 & p03a==1)), by(nqid)
		lab var head_nat "Head is Ghanaian"
		
	//Generate head education
	gen educ4 = 1 if (p12b<=3 & (p12c<6 | p12c==.)) | p12a==1 | p12b==16  //none or less than primary
	replace educ4 = 2 if (p12b==3 & p12c==6) | (p12b==4 & p12c<3) | (p12b==5 & p12c<4) | (p12b==7 & p12c<5)   //Primary completed - Note that secondary could either be 5 or 7 depending on when they finished
	replace educ4 = 3 if (p12b==4 & p12c==3) | (p12b==5 & p12c<=4) | (p12b==6 & p12c<4) //JHS | middle
	replace educ4 = 4 if (p12b==6 & p12c==4) | (p12b==7 & inrange(p12c, 5,7)) | inrange(p12b,11,15) | inrange(p12b,8,10) //SHS completed or higher 
lab var educ4 "Education levels"
lab def educ 1 "None or less than primary" 2 "Primary completed" 3 "JHS or middle completed" 4 "SHS completed or higher"

	egen head_edu = max(((a11c==1)*educ4)), by(nqid)
		lab var head_edu "Head's education level"
		lab val head_edu educ
	egen max_edu  = max(((p02>15)*educ4)), by(nqid)
		lab var max_edu "Max education for age>15 in the HH"
		lab val max_edu educ
		
	//Religion
	recode p09 (8=1) (1 2 3 4 = 2) (5 = 3) (7 9 = 4)
		
	//Generate number of women in the household
	egen num_female= sum((a11d==2)), by(nqid)
		lab var num_female "number of women in the household"
		
	//Generate number of men in the household
	egen num_male= sum((a11d==1)), by(nqid)
		lab var num_male "number of men in the household"
		
	//Generate number of individuals in household
	egen hhsize = count(pid), by(nqid)
		lab var hhsize "Number of members in HH"
	
	//Generate house type
	gen individual_dwell = inrange(h01,1,3)
		lab var individual_dwell "Sep, semidetach, flat house"
		
	//Outer wall type
	gen wall_concrete = h02==6
		lab var wall_concrete "Concrete wall construction"
	
	//Roofing material
	gen roofquality = inrange(h03,3,7)
		lab var roofquality "Wood, metal, slate, cement, tile roof"
	
	//Floor of dwelling
	gen floor_cement=h04==2
	gen floor_tiles=inrange(h04, 6,8)
	gen floor_other=inlist(h04,1,3,4,5,9)
	
		lab var floor_cement "Floor type is cemenet"
		lab var floor_tiles  "Floor type is tiles"
		lab var floor_other  "Floor type is not cement or tiles"
	
	//Owner occupied dwelling
	gen owner_occupy=h05==1
		lab var owner_occupy "Owner occupied dwelling"
		
	//Rooms per people
	gen rooms_people      = h07a/hhsize
	gen rooms_sleep_people = h07b/hhsize
		lab var rooms_people       "Rooms per people in HH"
		lab var rooms_sleep_people "Sleeping rooms per people in HH"
		

	//Main source of lighting
	gen lighting_main= h08a==1
	gen lighting_other= h08a!=1
		lab var lighting_main   "main source of lighting in hh"
		lab var  lighting_other  "other sources of linghting in hh"

	// Main source of cooking fuel
	gen cooking_fuel_wood = h09a==1
	gen cooking_fuel_lpg = h09a==2
	gen cooking_fuel_charcoal = h09a==6
	gen cooking_fuel_other= !inlist(h09a,1,2,6)
		lab var cooking_fuel_wood    "source of cooking fuel in hh using wood"
		lab var cooking_fuel_lpg     "source of cooking fuel in hh using lpg"
		lab var cooking_fuel_charcoal   "source of cooking fuel in hh using charcoal"
		lab var cooking_fuel_other    "source of cooking fuel in hh using other source"

	// Main source of drinking water
	gen improved_water = !inlist(h11a,12,13,14,15,16)
	gen pipe_water = inrange(h11a,1,4)
		lab var improved_water   "Source improved drinking water in hh"
		lab var pipe_water       "Pipe-borne source hh"
		
	//Main toilet facility
	gen improved_toilet = inlist(s03, 2,3)
	//gen improved_toilet = inlist(s03, 2,3,4,5,6)
	lab var improved_toilet "KVIP,VIP and Pit latrine"
	
