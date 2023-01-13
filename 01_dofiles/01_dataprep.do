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
	global main      "C:\Users\WB378870\OneDrive - WBG\000.EAWVP\0.Ghana\"
	global dpath "$main\0.Data\10.Census_2021"
	global outdata   "$main\6.SAE\1.data\"
}
if (lower("`c(username)'")=="jacqueline anum"){
	global dpath  "C:\2021PHC\tabulation\"
}
use "$dpath\defactopopn_10%_20221011d.dta" /*if _n<1000*/, clear

	//We keep only households
	keep if restype==1
	
*===============================================================================
// 0. Replicating the 2010 prep file
*===============================================================================
	//HH size
	egen hhsize = rowtotal(usual_males usual_females absent_males absent_females)
label var hhsize "Household size"

	//Urban
	g urban = (urbrur==1)
	label var urban "Urban = 1, Rural = 0"

	//Sex of the household head
	//Generate head sex
	egen head_male=max(((a11d==1) & a11c==1)), by(nqid)
	label var head_male "Household head is male = 1, 0 otherwise"
	//Prop of male in HH
	egen malep = mean(a11d==1), by(nqid)
	label var malep "Proportion of male members in the household"

	//Generate head age
	egen headage=max(((a11c==1)*p02)), by(nqid)
	lab var headage "Age of head of household"	
	
	//Avg. age in HH
	egen age_avg = mean(p02), by(nqid)
	label var age_avg "Average age of household members"

	//Dep ratio
	egen depratio = mean(age <= 14 | age >= 65)	, by(nqid)
	label var depratio "Dependency ratio"
	
	//Generate nationality of head
	egen head_nat = max((a11c==1 & p03a==1)), by(nqid)
		lab var head_nat "Head is Ghanaian"
	//SHare Ghanaian in HH
	egen ghanaianp = mean(p03a==1), by(nqid)
	label var ghanaianp "Proportion of household members who are Ghanaians"
	
	//Ethnicity of head
	clonevar ethnicity = p04a
	egen head_ethnicity = max(ethnicity*(a11c==1)), by(nqid)
	label var head_ethnicity "Ethnicity of the household head"
	lab val head_ethnicity `:val lab ethnicity'
	tab head_ethnicity, gen(head_ethnicity)

	*Region of birth of the household head - local
	gen birthplace = region if inlist(bornhere,1,2)
	replace birthplace = bornhere - 2 if !inlist(bornhere,1,2) & bornhere<=18
	lab val birthplace `:val lab region'
	replace birthplace = 19 if birthplace==.
	
	egen head_birthplace = max(birthplace*(a11c==1)), by(nqid)
	label var head_birthplace "Region of birth of the household head"
	tab head_birthplace, gen(head_birthplace)
	
	//Religion
	recode p09 (8 = 1) (1 2 3 4 = 2) (5 6 =3) (7 9 =4), gen(religion)
	label define religion 1 "No religion" 2 "Christian" 3 "Islam/Ahmadi" 4 "Traditionalist/Other"
	label values religion religion
	
	egen head_religion = max(religion*(a11c==1)), by(nqid)
	lab val head_religion religion
	
	//SHare Christian
	egen christianp = mean(religion==2), by(nqid)
	label var christianp "Proportion of household members who are Christians"

	//Marital status of the household head
	recode p10 (9=1) (1=2) (2 3 4 5 = 3) (6 = 4) (7 = 5) (8 = 6), gen(marital_status)
	
	egen head_maritalstatus = max(marital_status*(a11c==1)), by(nqid)
	label define marital 1 "Never married" 2 "Informal/consensual union/living together" 3 "Married" 4 "Separated" 5 "Divorced" 6 "Widowed"
	label val head_maritalstatus marital 
	label var head_maritalstatus "Marital status of the household head"
	tab head_maritalstatus, gen(head_maritalstatus)
	
	//Prop married
	egen marriedp = mean(marital_status==3), by(nqid)
	label var marriedp "Proportion of household members who are married"
	
	foreach x in nationality ethnicity birthplace birth sincebirth years_resident religion marital_status{
		cap drop `x'
	}

*===============================================================================
// Education
*===============================================================================

	//School attendance
	egen head_schooling = max(p12b*(a11c==1)), by(nqid)
	lab val head_schooling `:val lab p12b'
	label var head_schooling "School attendace of the household head"
	tab head_schooling, gen(head_schooling)
	
	//prop never attended school...
	egen noschoolingp = mean(p12b==1), by(nqid)
	label var noschoolingp "Proportion of household members who never attended school"
	
	// Highest level of schooling completed
	gen educ4 = 1 if (p12b<=3 & (p12c<6 | p12c==.)) | p12a==1 | p12b==16  //none or less than primary
	replace educ4 = 2 if (p12b==3 & p12c==6) | (p12b==4 & p12c<3) | (p12b==5 & p12c<4) | (p12b==7 & p12c<5)   //Primary completed - Note that secondary could either be 5 or 7 depending on when they finished
	replace educ4 = 3 if (p12b==4 & p12c==3) | (p12b==5 & p12c<=4) | (p12b==6 & p12c<4) //JHS | middle
	replace educ4 = 4 if (p12b==6 & p12c==4) | (p12b==7 & inrange(p12c, 5,7)) | inrange(p12b,11,15) | inrange(p12b,8,10) //SHS completed or higher 
	lab var educ4 "Education levels"
	lab def educ 1 "None or less than primary" 2 "Primary completed" 3 "JHS or middle completed" 4 "SHS completed or higher"
	lab val educ4 educ
	
	// FOr heads...
	egen head_educ = max(educ4*(a11c==1)), by(nqid)
	lab val head_educ educ
	tab head_educ, gen(head_educ)
	
*===============================================================================
// Employment
*===============================================================================

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

*===============================================================================
//Housing
*===============================================================================
//Mobile phone
egen mobileown = max((p19aa==1|p19ab==1)), by(nqid)
label var mobileown "1 = Any member of the household owns a mobile phone, 0 otherwise"


egen mobile_smart = max(p19aa==1), by(nqid)
label var mobile_smart "1 = Any member of the household owns a smart mobile phone"

// Fixed phone -> no longer relevant
egen fixedphone = max(h13b1==1), by(nqid)
label var fixedphone "1 = Household owns a fixed telephone line, 0 otherwise"

//Computer
egen pc = max(h13h1==1), by(nqid)
label var pc "1 = Any member of the household owns desktop or laptop computers, 0 otherwise"

g birth = 1 if bp12mt!=.
egen birth12mo = max(birth), by(nqid)
recode birth12mo (. = 0)
label var birth12mo "1 = Any live birth in the household in the last 12 months, 0 otherwise"

 


*Does any member of the household use internet facility
gen internet= (p19ca==1|p19cb==1|p19cc==1|p19cd==1|p19ce==1|p19cf==1) & p02>=6 
bys nqid: egen internetuse = max(internet)
label var internetuse "1 = Any member of the household uses internet, 0 otherwise"

//Agriculture
egen aghouse = max(p15b1==1), by(nqid)
label var aghouse "1 = Any household member engaged in agriculture, 0 otherwise"

*===============================================================================
// Dwelling CHaracteristics
*===============================================================================
//Type of dwelling
recode h01 (1 2 3 4 5 10 = 1) (6 7 8 9 11 12 = 0), gen(conventional)
label var conventional "1 = Conventional dwelling, 0 otherwise"
//Outerwall
recode h02 (1 7 = 1) (2 3 8 9 = 2) (4 5 6 10 11 = 3), gen(wall)
label var wall "Main construction material of outer wall"
label define wall 1 "Mud bricks/earth, Landcrete" 2 "Wood, Metal sheet/slate/asbestos, Bamboo, Palm leaves/thatch(grass/ruffian)" 3 "Stone, Burnt bricks, Cement blocks/concrete, Other"
label val wall wall
tab wall, gen(wall)
//Floor
recode h04 (1 = 1) (2 3 4 = 2)(5 6 7 8 9 = 3), gen(floor)
label var floor "Main construction material of floor"
label define floor 1 "Earth/mud" 2 "Cement/concrete, stone, burnt bricks" 3 "Wood, vinyl tiles, ceramic/porcelain/granite/marble tiles,terrazo/terrazo tiles, other"
label val floor floor
tab floor, gen(floor)
//Roofing
recode newh03 (1 7 8= 1) (2 4 6 = 2) (3 = 3) (5 9 10 = 4) , gen(roof)
label var roof "Main construction material of roof"
label define roof 1 "Mud/mud bricks/earth, bamboo, palm leaves/thatch(grass/ruffian)" 2 "Wood, slate/asbestos, roofing tile" 3 "Metal sheet" 4 "Concrete/Other"
label val roof roof
tab roof, gen(roof)
//Tenure
recode h05 (1 = 1) (2 = 2) (3/7 = 3), gen(tenure)
label var tenure "Tenancy arrangement"
label define tenure 1 "Owning" 2 "Renting" 3 "Rent free, perching, squatting"
label val tenure tenure
tab tenure, gen(tenure)
//# rooms
g rooms =  h07a
label var rooms "Number of rooms"

//# bedrooms
g bedrooms = h07b
label var bedrooms "Number of bedrooms"

//Drinking water
recode h11a (1 2 3 4 = 1) (5 6 8 = 2) (9 10 = 3) (7 11/16 = 4), gen(water_drinking)
label var water_drinking "Main source of drinking water"
label define water1 1 "Pipe inside or outside dwelling, public tap" 2 "Bore-hole/pump/tube well, protected well, protected spring" 3 "Bottled or satchet water" 4 "Rain water, tanker, unprotected well or spring, river/stream,dugout/pond/canal/lake/dam, other"
label val water_drinking water1
tab water_drinking, gen(water_drinking)

//General use water
*Water for general use
recode h11c (1 2 3 4 = 1) (5 6 8  = 2) (7 9/16 = 3), gen(water_general)
label var water_general "Main source of water for general use"
label define water2 1 "Pipe inside or outside dwelling, public tap" 2 "Bore-hole/pump/tube well, protected well, protected spring, satchet water" 3 "Rain water, tanker, unprotected well or spring, river/stream,dugout/pond/canal/lake/dam, other"
label val water_general water2
tab water_general, gen(water_general)

//COoking fuel
recode h09a (1 = 1) (6 = 2) (2 3 = 3) (4 5 7 8 9 10 11 = 4) (12=5), gen(fuel)
label var fuel "Main source of cooking fuel"
label define fuel 1 "Wood" 2 "Charcoal" 3 "Gas" 4 "Electricity, kerosense , crop residue, sawdust, animal waste, other" 5 "No Cook"
label val fuel fuel
tab fuel, gen(fuel)
//Toilet type -> Need to verify!
recode s03 (12 = 1) (4 5 6 8 = 2) (3 = 3) (2 = 4) (1 7 9 10 11 = 5), gen(toilet)
label var toilet "Type of toilet"
label define toilet 1 "No facility" 2 "WC" 3 "Pit latrine" 4 "KVIP" 5 "Bucket/pan, public toilet, other"
label val toilet toilet
tab toilet, gen(toilet)
//SOlid waste disposal

compress
save "$outdata\census_2021", replace
	

	

	
	
	


	
/* Previous file code
	
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




	
	





	
	

