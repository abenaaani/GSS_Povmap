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

use "C:\Desktop\Povmap\g7stata\g7PartA\g7sec1.dta" /*if _n<1000*/, clear

		
	//Data is at the individual level; unique at the nqid pid
	
	//Generate head sex
	egen headsex=max(((s1q2==2) & s1q2==1)), by(hid)
		lab var headsex "Female head of household"
		
	//Generate head age
	egen headage=max(((s1q3==1)*s1q5y)), by(hid)
		lab var headsex "Age of head of household"
	
	//Generate nationality of head
	egen head_nat = max((s1q3==1 & s1q12==1)), by(hid)
		lab var head_nat "Head is Ghanaian"
		
use "C:\Desktop\Povmap\g7stata\g7PartA\g7sec2.dta" /*if _n<1000*/, clear		
		
	//Generate head education
	gen educ4 = 0 if s2aq3<=3 & (s1q16a<6 | s1q16a==.)
	replace educ4 = 1 if (s2aq3==3 & s1q16a==6) | (s2aq3>3 & s2aq3<6) | (s2aq3==6 & s1q16a<3) | (s2aq3==7 & s1q16a<6)
	replace educ4 = 2 if (s2aq3==6 & (inlist(s1q16a,3,4))) | (s2aq3==7 & inlist(s1q16a,6,7)) | (inlist(s2aq3,8))
	egen head_edu = max(((s1q3==1)*))
	
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
