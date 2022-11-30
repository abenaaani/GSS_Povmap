set more off
clear all
//do file to prepare census data for poverty mapping
use "C:\Users\CHARLES K. AGBENU\Desktop\CENSUS REPORT\10%2021PHC_20220828d\defactopopn_10%_20220828d.dta" /*if _n<1000*/, clear

	//We keep only households
	keep if restype==1
	
	//Data is at the individual level; unique at the nqid pid
	
	//Generate head sex
	egen headsex=max(((a11d==2) & a11d==1)), by(nqid)
		lab var headsex "sex of head of household"
	
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
	gen room_sleep_people = h07b/hhsize
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
	gen cooking_fuel_other= ! inlist (h09a,1,2,6)
		lab var cooking_fuel_wood    "source of cooking fuel in hh using wood"
		lab var cooking_fuel_lpg     "source of cooking fuel in hh using lpg"
		lab var cooking_fuel_charcoal   "source of cooking fuel in hh using charcoal"
		lab var cooking_fuel_other    "source of cooking fuel in hh using other source"

	// Main source of drinking water
	gen improved_water = ! inlist(h11a,12,13,14,15,16)
	gen pipe_water = inrange(h11a,1,4)
		lab var improved_water   "Source improved drinking water in hh"
		lab var pipe_water       "Pipe-borne source hh"
