clear all
set more off


global pdata "C:\Users\WB378870\OneDrive - WBG\000.EAWVP\0.Ghana\0.Data\9.Census_2010"
global oput  "C:\Users\WB378870\GitHub\GSS_Povmap\Data FH"

//global census "C:\Users\Dhiraj Sharma\Dropbox\PREM\Ghana\GHA_dta\Census\Census"
//global cleandata "C:\Users\Dhiraj Sharma\Dropbox\PREM\Ghana\PovMap Data"

/*
Convert SPSS data to Stata:
*--------------------------

usespss "$census\2010 PHC -216D-10%Population@EA.sav", clear
save "$census\216D-10%Population", replace

usespss "$census\2010 PHC -216D-10%Housing@EA", clear
save "$census\216D-10%Housing", replace

usespss "$census\2010 PHC -10%Housing@EA.sav", clear
save "$census\10%housing", replace

usespss "$census\2010 PHC -10%Livestock@EA.sav", clear
save "$census\10%Livestock", replace
*/


*=======================================
*Prepare census data for poverty mapping
*=======================================
/*
//use "$census\10%population_original_stata12", clear
rename (REGION DISTRICT REGDIST DISTYPE SUBDIST) (region district regdist distype subdist)
rename (AGE NATIONALITY BIRTHELSE SEX RELATIONSHIP) (age nationality birthplace sex relationship)
keep if RESTYPE==1

drop ABSENT_MEMBERS USUALMALES USUALFEMALES VISITORMALES VISITORFEMALES ABSENTMALES ABSENTFEMALES ENUMMALES ENUMFEMALES ANYONE_DIED CROP_FARMING TREE_GROWING LIVE_STOCKRAISING FISHING AGMALES AGFEMALES
drop SIGHT HEARING SPEECH PHYSICAL INTELLECTUAL EMOTIONAL OTHERDISABILITY MCEB FCEB MCS FCS BIRTHLY DISABILITY

*/
/*
Definition of household member in GLSS:
--------------------------------------
In the last 12 months, the person has lived away from the household 6 months or less
OR
In the last 12 months, the person has lived away from the household for 6 months or more and if the person is:
	Head of the household
	Child under 9 months olds
	Has not been a member of another household
	Intends to stay in the household for at least 6 months

Census:
------
In the census, information is collected for visitors but not for absent members.
*/
//use "C:\phc2010\Popn_Housing\Popn_Housing.dta", clear
use "$pdata\2010phc-216d-10%population@ea.dta", clear
set more off

rename _all, lower
clonevar seqnum=hhid
//keep if inlist(region,1,2,3)
//keep if inlist(region,5,6,9)
//keep if inlist(region,4,7,8,10)


local todrop related0to17 related0to5 related_persons workers_in_family ///
complete_plumbing family_nucleus householdtype houses qtype ///
locur hh_comp agpopn loct3 esr temp form2 visitormales ///
visitorfemales own6to17 own0to5 own_children parents_working  ///
 parents_in_house birth_enum_region birth_loc_and_other ///
 subrelation subfamily birthly year34 year12 yob mob dob birthdate  ///
occupsmag occupmig industry indbs indmig occupation

foreach x of local todrop{
	cap drop `x'
}

//egen hhsize = rowtotal(USUALMALES USUALFEMALES ABSENTMALES ABSENTFEMALES)
egen hhsize = rowtotal(usualmales usualfemales absentmales absentfemales)
label var hhsize "Household size"

*Urban
g urban = (urban_rural==1)
label var urban "Urban = 1, Rural = 0"

*Sex of the household head
g head_male = 2 - headsex
drop headsex
label var head_male "Household head is male = 1, 0 otherwise"

*Proportion of male in the household
g male = (2 - sex)
bys seqnum: egen malep = mean(male)
label var malep "Proportion of male members in the household"

*Age of the household head
g head_age = age if relationship==1
label var head_age "Age of the household head"

*Average age in the household
bys seqnum: egen age_avg = mean(age)
label var age_avg "Average age of household members"

*Dependency ratio = (Number of household members aged less than 15 or more than 64)/Household size
bys seqnum: g nonworkingage = (age <= 14 | age >= 65)
bys seqnum: egen totnonworkingage = sum(nonworkingage)
g depratio = totnonworkingage/hhsize
label var depratio "Dependency ratio"

*Nationality of the household head
recode nationality (2/16 = 2)
g ghanaian = 2 - nationality
g head_ghanaian = ghanaian if relationship==1
label var head_ghanaian "Household head is Ghanaian = 1, 0 otherwise"

*Proportion of household members who are Ghanaian
bys seqnum: egen ghanaianp = mean(ghanaian)
label var ghanaianp "Proportion of household members who are Ghanaians"

*Ethnicity of the household head
ren ethnicity ethnic
recode ethnic (0/19=1) (20/22=2) (30=3) (40/48=4) (50/59=5) (60/69=6) (70/75=7) (80/82=8) (90/94=9) (97=10), gen(ethnicity)
label define ethnicity  1 "Akan"     2 "Ga"   3 "Ewe"  4 "Guan"  5 "Gurma"  6 "Mole-Dagbon"  7 "Grusi"  8 "Mande"  9 "Other" 10 "Foreigners"
label values ethnicity ethnicity

g head_ethnicity = ethnicity if relationship==1
label var head_ethnicity "Ethnicity of the household head"
tab head_ethnicity, gen(head_ethnicity)

*Region of birth of the household head
ren birthplace  birth
ren birthelse birthplace
recode birthplace (11/23 = 11)
g head_birthplace = birthplace if relationship==1
label var head_birthplace "Region of birth of the household head"
tab head_birthplace, gen(head_birthplace)

*Religion of the household head
//recode religion (1 = 1) (2 3 4 5 = 2) (6 7 = 3) (8 9 = 4), gen(religion)
//label define religion 1 "No religion" 2 "Christian" 3 "Islam/Ahmadi" 4 "Traditionalist/Other"
//label values religion religion
g head_religion = religion if relationship==1
label var head_religion "Religion of the household head"
tab head_religion, gen(head_religion)

*Proportion of households members who are Christians
g christian = (religion==2)
bys seqnum: egen christianp = mean(christian)
label var christianp "Proportion of household members who are Christians"

*Marital status of household head
g head_maritalstatus = marital_status if relationship==1
label var head_maritalstatus "Marital status of the household head"
tab head_maritalstatus, gen(head_maritalstatus)

*Proportion of married household members
g married = (marital_status==1)
replace married = . if age < 12 | marital_status==.
bys seqnum: egen marriedp = mean(married)
label var marriedp "Proportion of household members who are married"

//drop ETHNICITY RELIGION nationality MARITAL_STATUS birthplace 
drop nationality ethnicity birthplace birth sincebirth years_resident religion marital_status
*School attendance of the household head
g head_schooling = school_attend if relationship==1
label define schooling 1 "Never attended school" 2 "Still in school" 3 "Attended school in the past"
label val head_schooling schooling
label var head_schooling "School attendace of the household head"
tab head_schooling, gen(head_schooling)

*Proportion of household members who never attended school
g noschooling = (school_attend==1)
replace noschooling = . if school_attend==.
bys seqnum: egen noschoolingp = mean(noschooling)
label var noschoolingp "Proportion of household members who never attended school"

/*Highest level of schooling completed:
None or less than primary	= 1
Primary						= 2
JSS/JHS						= 3
Middle						= 4
SSS/SHS	or above			= 5
*/
g schlvl = 1 if school_attend==1 
 
replace schlvl = 1 if (school_attend == 2 & edlevel==1)|(school_attend==2 & edlevel==2)|(school_attend==2 & edlevel==3)
replace schlvl = 2 if (school_attend == 2 & edlevel==4)
replace schlvl = 3 if (school_attend == 2 & edlevel==5)
replace schlvl = 4 if (school_attend == 2 & edlevel==6)
replace schlvl = 5 if (school_attend == 2 & edlevel>=7 & edlevel!=.)

replace schlvl = 1 if (school_attend==3 & edlevel==1) | (school_attend==3 & edlevel==2) | (school_attend==3 & edlevel==3 & edgrade <= 5)
replace schlvl = 2 if (school_attend==3 & edlevel==3 & edgrade==6) | (school_attend==3 & edlevel==4 & edgrade <= 2)
replace schlvl = 3 if (school_attend==3 & edlevel==4 & edgrade == 3) | (school_attend==3 & edlevel==5 & edgrade <=3 )
replace schlvl = 4 if (school_attend==3 & edlevel==5 & edgrade == 4) | (school_attend==3 & edlevel==6 & edgrade <=3 )
replace schlvl = 5 if (school_attend==3 & edlevel==6 & edgrade == 4) | (school_attend==3 & edlevel>=7 & edlevel!=.)

label define schlvl 1 "None or less than primary" 2 "Primary" 3 "JSS/JHS" 4 "Middle" 5 "SSS/SHS or above"
label val schlvl schlvl
label var schlvl "Highest level of schooling completed by the household head"
tab schlvl if relationship==1, gen(head_schlvl)

drop school_attend 


*Labor market status of the household head
rename econact head_employed 
tab head_employed if relationship==1, gen(head_employed)

*Proportion of household members employed
g employed = (head_employed==1)
bys seqnum: egen employedp = mean(employed)
label var employedp "Proportion of household members employed"

/*Occupation of the household head
recode occupmag (0 = 10), gen(occupation)
replace occupation = 0 if employed==0
label define occupation 0 "Unemployed" 1 "Legislators/managers" 2 "Professionals" 3 "Technicians and associate professionals" ///
						4 "Clerical support workers" 5 "Service/sales workers" 6 "Skilled agric/fishery workers" 7 "Craft and related trades workers" ///
						8 "Plant machine operators and assemblers" 9 "Elementary occupations" 10 "Other Occupations"
label values occupation occupation
g head_occ = occupation if relationship==1
label values head_occ occupation
tab head_occ, gen(head_occ)
*/
*Employment status of the household head
g head_empstatus = empstatus if relationship==1
replace head_empstatus = 0 if occupmag==. & relationship==1
label define empstatus 0 "Unemployed/Inactive" 1 "Employee" 2 "Self employed without employees" 3 "Self employed with employees" ///
					   4 "Casual worker" 5 "Contributing family worker" 6 "Apprentice" 7 "Domestic employee (househelp)" 8 "Other"
label values head_empstatus empstatus
tab head_empstatus, gen(head_empstatus)

*Proportion of household members who are paid employees
g employee = (empstatus==1)
replace employee = . if empstatus==.
bys seqnum: egen employeep = mean(employee)
label var employeep "Proportion of household members who are paid employees"					   

drop worked occupmag empstatus


/*
*Any disabled household member?
g disability = 1 if SIGHT ==1 | HEARING ==1 | SPEECH ==1 | PHYSICAL ==1 | INTELLECTUAL ==1 | OTHERDISABILITY ==1
replace disability = 0 if SIGHT ==2 & HEARING ==2 & SPEECH ==2 & PHYSICAL ==2 & INTELLECTUAL ==2 & OTHERDISABILITY ==2
bys HHID: egen anydisabled = max(disability)

*Proportion of household members disabled
bys HHID: egen disabledp = mean(disability)
*/

/*
*Does any member of the household own mobile phone
bys seqnum: egen mobileown = min(mobile_phone)
replace mobileown = 2 - mobile_phone
label var mobileown "1 = Any member of the household owns a mobile phone, 0 otherwise"
*/
*Does any member of the household use internet facility
bys seqnum: egen internetuse = min(internet)
replace internetuse = 2 - internetuse
label var internetuse "1 = Any member of the household uses internet, 0 otherwise"

cap drop mobile_phone 
cap drop internet

/*Survive rate
g surviverate = CS/CEB

drop CS CEB

*Any birth in the last 12 months?
g birth = 1 if (MLAST12 > 0 & MLAST12 < .) | (FLAST12 > 0 & FLAST12 < .) & age>=12 & age<=49
bys HHID: egen birth12mo = max(birth)
recode birth12mo (. = 0)
label var birth12mo "1 = Any live birth in the household in the last 12 months, 0 otherwise"

drop MLAST* FLAST* 


*Housing and Livestock Characteristics
*=======================

merge m:1 HHID using "$census\10%housing"
drop _me
keep if RESTYPE==1
*/
*Does the household have a fixed telephone line at home?
g fixedphone = 2 - fixed_phoneline
label var fixedphone "1 = Household owns a fixed telephone line, 0 otherwise"
drop fixed_phoneline

*Does any member of the household own desktop or laptop computers?
g pc = 2 - desktop_computer
label var pc "1 = Any member of the household owns desktop or laptop computers, 0 otherwise"
drop desktop_computer

*Any member of the household does agricultural activity
//rename AGHOUSE aghouse
replace aghouse = 2 - aghouse
label var aghouse "1 = Any household member engaged in agriculture, 0 otherwise"

*Type of dwelling
recode dwelling (1 2 3 4 5 6 9 = 1) (7 8 10 11 = 0), gen(conventional)
label var conventional "1 = Conventional dwelling, 0 otherwise"
drop dwelling

*Material of outer wall
recode walls (1 7 = 1) (2 3 8 9 = 2) (4 5 6 10 = 3), gen(wall)
label var wall "Main construction material of outer wall"
label define wall 1 "Mud bricks/earth, Landcrete" 2 "Wood, Metal sheet/slate/asbestos, Bamboo, Palm leaves/thatch(grass/ruffian)" 3 "Stone, Burnt bricks, Cement blocks/concrete, Other"
label val wall wall
tab wall, gen(wall)
drop walls

*Floor
ren floor floors
recode floors (1 = 1) (2 3 4 = 2)(5 6 7 8 9 = 3), gen(floor)
label var floor "Main construction material of floor"
label define floor 1 "Earth/mud" 2 "Cement/concrete, stone, burnt bricks" 3 "Wood, vinyl tiles, ceramic/porcelain/granite/marble tiles,terrazo/terrazo tiles, other"
label val floor floor
tab floor, gen(floor)

*Roof
ren roof roofs
recode roofs(1 7 8 = 1)(2 4 6 = 2)(3 = 3)(5 9 = 4), gen(roof)
label var roof "Main construction material of roof"
label define roof 1 "Mud/mud bricks/earth, bamboo, palm leaves/thatch(grass/ruffian)" 2 "Wood, slate/asbestos, roofing tile" 3 "Metal sheet" 4 "Concrete/Other"
label val roof roof
tab roof, gen(roof)

*Tenure
ren tenure tenures
recode tenures (1 = 1) (2 = 2) (3/6 = 3), gen(tenure)
label var tenure "Tenancy arrangement"
label define tenure 1 "Owning" 2 "Renting" 3 "Rent free, perching, squatting"
label val tenure tenure
tab tenure, gen(tenure)
drop tenure

*Number of rooms
//g rooms = rooms
//drop rooms
label var rooms "Number of rooms"

*Number of bedrooms
//g bedrooms = BEDROOMS
//drop BEDROOMS
label var bedrooms "Number of bedrooms"

*Main source of lighting
ren lighting light
recode light (1 2 5 = 1) (3 4 = 2) (7 = 3) (6 8 9 10 = 4), gen(lighting)
label var lighting "Main source of lighting"
label define lighting 1 "Electricity(mains), electricity(private generator),solar energy" 2 "Kerosene or gas lamp" 3 "Flashlight/torch" 4 "Candle, firewood, crop residue, other"
label val lighting lighting
tab lighting, gen(lighting)
drop light

*Source of drinking water
ren water_drinking water
recode water (1 2 3 = 1) (4 5 7 = 2) (8 9 = 3) (6 10/16 = 4), gen(water_drinking)
label var water_drinking "Main source of drinking water"
label define water1 1 "Pipe inside or outside dwelling, public tap" 2 "Bore-hole/pump/tube well, protected well, protected spring" 3 "Bottled or satchet water" 4 "Rain water, tanker, unprotected well or spring, river/stream,dugout/pond/canal/lake/dam, other"
label val water_drinking water1
tab water_drinking, gen(water_drinking)
drop water

*Source of water for general use
recode water_source (1 2 3 = 1) (4 5 7 = 2) (6 8/13 = 3), gen(water_general)
label var water_general "Main source of water for general use"
label define water2 1 "Pipe inside or outside dwelling, public tap" 2 "Bore-hole/pump/tube well, protected well, protected spring, satchet water" 3 "Rain water, tanker, unprotected well or spring, river/stream,dugout/pond/canal/lake/dam, other"
label val water_general water2
tab water_general, gen(water_general)
drop water_source

*Cooking fuel
recode cooking_fuel (2 = 1) (6 = 2) (3 = 3) (1 4 5 7/10 = 4), gen(fuel)
label var fuel "Main source of cooking fuel"
label define fuel 1 "Wood" 2 "Charcoal" 3 "Gas" 4 "Electricity, kerosense, crop residue, sawdust, animal waste, other"
label val fuel fuel
tab fuel, gen(fuel)
drop cooking_fuel

*Type of toilet
ren toilet toilets
recode toilets (1 = 1) (2 = 2) (3 = 3) (4 = 4) (5/7 = 5), gen(toilet)
label var toilet "Type of toilet"
label define toilet 1 "No facility" 2 "WC" 3 "Pit latrine" 4 "KVIP" 5 "Bucket/pan, public toilet, other"
label val toilet toilet
tab toilet, gen(toilet)
drop toilets

*Solid waste disposal
recode rubbish (1 = 1) (2 6 = 2) (3 4 = 3) (5 7 = 4), gen(solidwaste)
label var solidwaste "How is refuse disposed"
label define rubbish 1 "Collected" 2 "Burned by household" 3 "Public dump" 4 "Dumped indiscriminately"
label val solidwaste rubbish
tab solidwaste, gen(solidwaste)
drop rubbish

//preserve
local vars hhsize head_male male head_age age depratio head_ghanaian ghanaian head_ethnicity1 - head_ethnicity10 ///
		head_birthplace1 - head_birthplace11 head_religion1 - head_religion4 christian head_maritalstatus1 - head_maritalstatus6 married ///
		noschooling head_schlvl1 - head_schlvl5 employed /*head_occ1 - head_occ11*/ head_empstatus1 - head_empstatus9 employee ///
		internetuse /*birth12mo surviverate */fixedphone pc aghouse conventional wall1 - wall3 floor1 - floor3 roof1 - roof4 tenure1 - tenure3 rooms bedrooms ///
		lighting1 - lighting4 water_drinking1 - water_drinking4 water_general1 - water_general3 fuel1 - fuel4 toilet1 - toilet5 solidwaste1 - solidwaste4 /*numlivestock*/
gen pop = 10
groupfunction, mean(`vars') sum(pop) by(region district)

save "$oput\FHcensus_district.dta", replace

sss
		
/*
foreach x of varlist `vars' {
keep region district ea `x'
collapse (mean) `x'_eamean = `x', by(region district ea)
format `x'_eamean %9.2f
//merge 1:1 region district ea using "$cleandata\areamean"
//drop _me
order `x'_eamean, last
//save "$cleandata\areamean", replace
//restore
//preserve
}
//restore

//preserve
local vars hhsize head_male male head_age age depratio head_ghanaian ghanaian head_ethnicity1 - head_ethnicity10 ///
		head_birthplace1 - head_birthplace2 head_religion1 - head_religion4 christian head_maritalstatus1 - head_maritalstatus6 married ///
		noschooling head_schlvl1 - head_schlvl5 employed head_occ1 - head_occ11 head_empstatus1 - head_empstatus9 employee ///
		 internetuse /*surviverate birth12mo*/ fixedphone pc aghouse conventional wall1 - wall3 floor1 - floor3 roof1 - roof4 tenure1 - tenure3 rooms bedrooms ///
		lighting1 - lighting4 water_drinking1 - water_drinking4 water_general1 - water_general3 fuel1 - fuel4 toilet1 - toilet5 solidwaste1 - solidwaste4 /*numlivestock*/
foreach x of varlist `vars' {
keep region district ea `x'
collapse (mean) `x'_distmean = `x', by(region district)
format `x'_distmean %9.2f
//merge 1:m region district using "$cleandata\areamean"
//drop _me
order `x'_distmean, last
//save "$cleandata\areamean", replace
restore
preserve
}
restore

preserve
local vars hhsize head_male male head_age age depratio head_ghanaian ghanaian head_ethnicity1 - head_ethnicity10 ///
		head_birthplace1 - head_birthplace11 head_religion1 - head_religion4 christian head_maritalstatus1 - head_maritalstatus6 married ///
		noschooling head_schlvl1 - head_schlvl5 employed head_occ1 - head_occ11 head_empstatus1 - head_empstatus9 employee ///
		 internetuse birth12mo surviverate fixedphone pc aghouse conventional wall1 - wall3 floor1 - floor3 roof1 - roof4 tenure1 - tenure3 rooms bedrooms ///
		lighting1 - lighting4 water_drinking1 - water_drinking4 water_general1 - water_general3 fuel1 - fuel4 toilet1 - toilet5 solidwaste1 - solidwaste4 numlivestock
foreach x of varlist `vars' {
keep region district ea `x'
collapse (mean) `x'_regionmean = `x', by(region)
format `x'_regionmean %9.2f
//merge 1:m region using "$cleandata\areamean"
//drop _me
order `x'_regionmean, last
//save "$cleandata\areamean", replace
restore
preserve
}
restore
******************

//use census123,clear

//se census569,clear

//use census47810,clear


*Hierarchical ID
*===============

keep if relationship==1
local vars aghouse hhsize head_male malep head_age age_avg head_ghanaian ghanaianp head_ethnicity1 - head_ethnicity10 ///
		head_birthplace1 - head_birthplace11 head_religion1 - head_religion4 christianp head_maritalstatus1 - head_maritalstatus6 marriedp ///
		head_schlvl1 - head_schlvl3 noschoolingp employedp /*head_occ1 - head_occ11 */ head_empstatus1 - head_empstatus9 employeep ///
		 internetuse /*birth12mo surviverate */ fixedphone pc  conventional wall1 - wall3 floor1 - floor3 roof1 - roof4 tenure1 - tenure3 rooms bedrooms ///
		lighting1 - lighting4 water_drinking1 - water_drinking4 water_general1 - water_general3 fuel1 - fuel4 toilet1 - toilet5 solidwaste1 - solidwaste4 
keep region district subdist distype ea urban `vars'

//merge m:1 region district ea using "$cleandata\areamean"
//drop _me
gen metro=(distype*100) + subdist

replace region = region + 10
//g long id = region*100000 + district*1000 + ea
g long id = (region*100000000) + (district*1000000) + (metro*1000) + ea

order id region district ea urban, first

local vars aghouse hhsize head_male malep head_age age_avg head_ghanaian ghanaianp head_ethnicity1 - head_ethnicity10 ///
		head_birthplace1 - head_birthplace11 head_religion1 - head_religion4 christianp head_maritalstatus1 - head_maritalstatus6 marriedp ///
		head_schlvl1 - head_schlvl3 noschoolingp employedp /*head_occ1 - head_occ11 */ head_empstatus1 - head_empstatus9 employeep ///
		 internetuse /*birth12mo surviverate */ fixedphone pc  conventional wall1 - wall3 floor1 - floor3 roof1 - roof4 tenure1 - tenure3 rooms bedrooms ///
		lighting1 - lighting4 water_drinking1 - water_drinking4 water_general1 - water_general3 fuel1 - fuel4 toilet1 - toilet5 solidwaste1 - solidwaste4 
		
ss

foreach x of varlist `vars' {
egen `x'_eamean = mean(`x'), by (region district metro ea)
egen `x'_distmean = mean(`x'), by (region district)
egen `x'_regionmean = mean(`x'), by (region)
format `x'_eamean `x'_distmean `x'_regionmean %9.2f
}
*

//save census123b,replace

//save census569b,replace

save census47810b,replace
s

//save "$cleandata\census", replace

*****************
use census47810b,clear
append using census123b

save census12347810,replace

append using census569b

save census2010, replace




mean urban hhsize - solidwaste4 //*_eamean *_distmean *_regionmean
