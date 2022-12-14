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
	global dpath "C:\Users\WB378870\OneDrive - WBG\000.EAWVP\0.Ghana\0.Data\10.Census_2021"
}
if (lower("`c(username)'")=="jacqueline anum"){
	global dpath  "C:\2021PHC\tabulation\"
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
	
		lab var floor_cement "Floor type is cement"
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

*Labor market status of the household head
tab econact if a11c==1, gen(head_employed)

*Proportion of household members employed
bys nqid: egen employedp = mean((econact==1)) 
label var employedp "Proportion of household members employed"

*Occupation of the household head
recode p14b1 (0 = 10), gen(occupation)
replace occupation = 0 if inlist(econact,2,3)
label define occupation 0 "Notworking" 1 "Legislators/managers" 2 "Professionals" 3 "Technicians and associate professionals" ///
						4 "Clerical support workers" 5 "Service/sales workers" 6 "Skilled agric/fishery workers" 7 "Craft and related trades workers" ///
						8 "Plant machine operators and assemblers" 9 "Elementary occupations" 10 "Other Occupations"
label values occupation occupation
g head_occ = occupation if a11c==1
label values head_occ occupation
label var occupation "Occupation of household head"

tab head_occ, gen(head_occ)
*
*Employment status of the household head
g head_empstatus = p16 if a11c==1
replace head_empstatus = 0 if p16==. & a11c==1
label define empstatus 0 "Notworking" 1 "Employee" 2 "Self employed without employees" 3 "Self employed with employees" ///
					   4 "Casual worker" 5 "Contributing family worker" 6 "Paid apprentice" 7 "Unpaid apprentice" 8 "Domestic employee (househelp)" 9 "Other"
label values head_empstatus empstatus
tab head_empstatus, gen(head_empstatus)

*Proportion of household members who are paid employees
*only employees
g employee = (p16==1)
replace employee = . if p16==.
bys nqid: egen employeep = mean(employee)
label var employeep "Proportion of household members who are paid employees"					   

*all paid workers - employees, paid apprentices, casual workers
g employeew = (inlist(p16,1,4,6))
replace employeew = . if p16==.
bys nqid: egen employeewp = mean(employeew)
label var employeewp "Proportion of household members who are paid workers"					   


*Employment sector of the household head
g head_empsector = p17 if a11c==1
replace head_empsector = 0 if p17==. & a11c==1
replace head_empsector = 5 if inrange(p17,5,9) & a11c==1
label define empsector 0 "Notworking" 1 "Public" 2 "Semi-Public/Parastatal" 3 "Private formal" ///
					   4 "Private Informal" 5 "NGO(Local/Int/Religious)" 
label values head_empsector empsector
tab head_empsector, gen(head_empsector)

*Industry of the household head
replace p15b1 = 0 if inlist(econact,2,3)
recode p15b1 (1=1) (2/6=2) (7/21=3),gen(industry)
label define industry 0 "Notworking" 1 "Agriculture" 2 "Industrial" 3 "Services" 
label values industry industry
g head_indus = industry if a11c==1
label values head_indus industry
label var industry "industrial sector of household head"

tab head_indus, gen(head_indus)

*
*Any disabled household member?
gen disability=0 if p18a==1 & p18b==1 & p18c==1 & p18d==1 & p18e==1 & p18f==1
replace disability = 1 if disability==. & p02>=5
bys nqid: egen anydisabled = max(disability)

*Proportion of household members disabled
bys nqid: egen disabledp = mean(disability)
label var disabledp "Proportion of household members disabled"					   


******************
*Any orphan household member?
gen orphanhood=1 if a11f==1 & a11g==1 & inrange(p02,0,17)
replace orphanhood = 0 if orphanhood==. 
bys nqid: egen orphaned = max(orphanhood)

*Does any member of the household own mobile phone
gen mobile_phone=1 if p19aa==1|p19ab==1|p19ac==1  //includes a tablet
replace mobile_phone=0 if mobile_phone==.
bys nqid: egen mobileown = max(mobile_phone)
label var mobileown "1 = Any member of the household owns a mobile phone, 0 otherwise"


*Does any member of the household use internet facility
gen internet=1 if (p19ca==1|p19cb==1|p19cc==1|p19cd==1|p19ce==1|p19cf==1) & p02>=6 
replace internet=0 if internet==.
bys nqid: egen internetuse = min(internet)
replace internetuse = 2 - internetuse

bys nqid: egen internetuse = max(internet)
label var internetuse "1 = Any member of the household uses internet, 0 otherwise"




	
	





	
	

