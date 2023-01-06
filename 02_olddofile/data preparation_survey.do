clear all
set more off

*global glss "C:\Users\wb425117\Dropbox\PREM\Ghana\GHA_dta\GLSS6\02_CLEANDATA"
*global expenditure "C:\Users\wb425117\Dropbox\PREM\Ghana\GHA_dta\GLSS6\04_AGGDATA"
*global census "C:\Users\wb425117\Dropbox\PREM\Ghana\GHA_dta\Census\Census"


*=======================================
*Prepare survey data for poverty mapping
*=======================================

use "$glss\SEC1", clear
merge m:1 HID using "$glss\g6loc_edt"
drop _me

merge 1:1 HID PID using "$glss\SEC2a"
drop _me

merge 1:1 HID PID using "$glss\SEC4a"
drop _me

merge 1:1 HID PID using "$glss\SEC4d"
drop _me

merge 1:1 HID PID using "$glss\SEC3a"
drop _me

merge m:1 HID using "$glss\SEC7"
drop _me

merge 1:1 HID PID using "$glss\SEC3d"
drop _me

merge m:1 HID using "$glss\SEC6"
drop _me



*Section 1: (Demographic variables)
*==================================

rename (s1q2 s1q5y s1q24) (sex age hhmem)

*Urban/rural
g urban = (urbrur==1)
label var urban "Urban = 1, Rural = 0"

*Household head
g hhead = 1 if s1q3==1

*Household size
sum hhsize [aw=weight]
label var hhsize "Household size"

*Sex of the household head
g head_male = 1 if sex==1 & hhead==1
replace head_male = 0 if sex==2 & hhead==1
label var head_male "Household head is male = 1, 0 otherwise"

*Proportion of male in the household
g male = 2 - sex
bys HID: egen malep = mean(male) if hhmem==1
label var malep "Proportion of male members in the household"

*Age of the household head
g head_age = age if hhead==1
label var head_age "Age of the household head"

*Average age in the household
bys HID: egen age_avg = mean(age) if hhmem==1
label var age_avg "Average age of household members"

*Dependency ratio
bys HID: g nonworkingage = (age <= 14 | age >= 65)
bys HID: egen totnonworkingage = sum(nonworkingage)
bys HID: g workingage = (age >= 15 & age <= 64)
bys HID: egen totworkingage = sum(workingage)
g depratio = totnonworkingage/totworkingage
label var depratio "Dependency ratio"

*Nationality of the household head
recode s1q12 (4/16 = 2), gen(nationality)
g ghanaian = 2 - nationality
g head_ghanaian = ghanaian if hhead==1
label var head_ghanaian "Household head is Ghanaian = 1, 0 otherwise"

*Proportion of household members who are Ghanaians
bys HID: egen ghanaianp = mean(ghanaian) if hhmem==1
label var ghanaianp "Proportion of household members who are Ghanaians"

*Ethnicity of the household head
replace s1q13a = 97 if s1q12>=3 & s1q12<=16 
recode s1q13a (0/19=1) (20/22=2) (30=3) (40/48=4) (50/59=5) (60/69=6) (70/75=7) (80/82=8) (90/94=9) (97=10), gen(ethnicity)
label define ethnicity  1 "Akan"     2 "Ga"   3 "Ewe"  4 "Guan"  5 "Gurma"  6 "Mole-Dagbon"  7 "Grusi"  8 "Mande"  9 "Other" 10 "Foreigners"
label values ethnicity ethnicity
drop if ethnicity==32
g head_ethnicity = ethnicity if hhead==1
label var head_ethnicity "Ethnicity of the household head"
tab head_ethnicity, gen(head_ethnicity)

*Region of birth of the household head
recode s1q11 (96 97 98 = 11)
g head_birthplace = s1q11 if hhead==1
label var head_birthplace "Region of birth of the household head"
tab head_birthplace, gen(head_birthplace)

*Religion of the household head
recode s1q10 (1 = 1) (2 3 4 5 = 2) (6 7 = 3) (8 9 = 4), gen(religion)
label define religion 1 "No religion" 2 "Christian" 3 "Islam/Ahmadi" 4 "Traditionalist/Other"
label values religion religion
g head_religion = religion if hhead==1
label var head_religion "Religion of the household head"
tab head_religion, gen(head_religion)

*Proportion of households members who are Christians
g christian = (religion==2)
bys HID: egen christianp = mean(christian)
label var christianp "Proportion of household members who are Christians"

*Marital status of the household head
recode s1q6 (1 = 3) (2 = 2) (3 = 4) (4= 5) (5 = 6) (6 = 1), gen(marital_status)
g head_maritalstatus = marital_status if hhead==1
label define marital 1 "Never married" 2 "Informal/consensual union/living together" 3 "Married" 4 "Separated" 5 "Divorced" 6 "Widowed"
label val head_maritalstatus marital 
label var head_maritalstatus "Marital status of the household head"
tab head_maritalstatus, gen(head_maritalstatus)

*Proportion of household members who are married
g married = (marital_status==3)
replace married = . if marital_status==.
bys HID: egen marriedp = mean(married)
label var marriedp "Proportion of household members who are married"


*Section 2 (Education)
*=====================

*School attendance of the household head
g attendance = 1 if s2aq1==2 //Never attended school
replace attendance = 2 if s2aq5==1 & attendance==. //Still in school
replace attendance = 3 if attendance==. //Attended school in the past
g head_schooling = attendance if hhead==1
label define schooling 1 "Never attended school" 2 "Still in school" 3 "Attended school in the past"
label val head_schooling schooling
label var head_schooling "School attendace of the household head"
tab head_schooling, gen(head_schooling)

*Proportion of household members who never attended school
g noschooling = (attendance==1)
replace noschooling = . if attendance==.
bys HID: egen noschoolingp = mean(noschooling)
label var noschoolingp "Proportion of household members who never attended school"

/*Highest level of schooling completed:
None or less than primary	= 1
Primary						= 2
JSS/JHS						= 3
Middle						= 4
SSS/SHS	or above			= 5
*/
g schlvl = 1 if s2aq1==2 | s2aq2<=15
replace schlvl = 2 if s2aq2>=16 & s2aq2<=18
replace schlvl = 3 if s2aq2>=19 & s2aq2<=22
replace schlvl = 4 if s2aq2>=23 & s2aq2<=26
replace schlvl = 5 if s2aq2>=27 & s2aq2!=.
label define schlvl 1 "None or less than primary" 2 "Primary" 3 "JSS/JHS" 4 "Middle" 5 "SSS/SHS or above"
label val schlvl schlvl
label var schlvl "Highest level of schooling completed by the household head"
tab schlvl if hhead==1, gen(head_schlvl)


*Section 4 (Employment and occupation)
*=====================================

/*Labor market status of the household head:

Employed 	= Worked in the last 7 days or available for work
Unemployed 	= Didn't work in the last 7 days but available for work and seeking work
Inactive	= Didn't work in the last 7 days and not available or not seeking work
*/

g employed = 1 if (s4aq1==1 | s4aq2==1 | s4aq3==1)
replace employed = 2 if (s4dq1==1)
replace employed = 3 if (s4dq1==2 | s4dq1==3)
g head_employed = employed if hhead==1
label define employment 1 "Employed" 2 "Unemployed" 3 "Inactive"
label val head_employed employment
tab head_employed, gen(head_employed)

*Proportion of household members employed
g employed_ = (employed==1)
bys HID: egen employedp = mean(employed_)
label var employedp "Proportion of household members employed"

*Major occupation categories
recode s4aq6 (110/310=10) (1111/1439 =1) (2111/2659=2) (3111/3522=3) (4110/4419=4) (5111/5419=5) (6111/6340=6) (7111/7549=7) (8111/8350=8) (9111/9629=9), gen(occupation)
replace occupation = 0 if employed==2|employed==3
g head_occ = occupation if hhead==1
label define occupation 0 "Unemployed" 1 "Legislators/managers" 2 "Professionals" 3 "Technicians and associate professionals" ///
						4 "Clerical support workers" 5 "Service/sales workers" 6 "Skilled agric/fishery workers" 7 "Craft and related trades workers" ///
						8 "Plant machine operators and assemblers" 9 "Elementary occupations" 10 "Other Occupations"
label values head_occ occupation
tab head_occ, gen(head_occ)

*Employment status of the household head
recode s4aq20 (1 = 1) (3 6 = 2) (2 5 = 3) (4 7 = 5) (8 = 7) (9 = 4) (10 = 6) (11 = 8), gen(empstatus)
replace empstatus = 0 if (s4aq1==2 & s4aq2==2 & s4aq3==2)
g head_empstatus = empstatus if hhead==1
label define empstatus 0 "Unemployed/Inactive" 1 "Employee" 2 "Self employed without employees" 3 "Self employed with employees" ///
					   4 "Casual worker" 5 "Contributing family worker" 6 "Apprentice" 7 "Domestic employee (househelp)" 8 "Other"
label values head_empstatus empstatus
tab head_empstatus, gen(head_empstatus)

*Proportion of household members who are paid employees
g employee = (empstatus==1)
bys HID: egen employeep = mean(employee)
label var employeep "Proportion of household members who are paid employees"					   


/*
*Section 3A (disability)
*======================

*Any household member disabled?
g disability = 2 - s3aq26
bys HID: egen anydisabled = max(disability)

*Proportion of household members disabled
bys HID: egen disabledp = mean(disability)
*/


*Section 7 (Housing)
*==================

*Does any member of the household own mobile phone?
g mobileown = 2 - s7eq1b
label var mobileown "1 = Any member of the household owns a mobile phone, 0 otherwise"

*Does any member of the household use internet?
g internetuse = 2 - s7eq3d
replace internetuse = 0 if s7eq2d==2
label var internetuse "1 = Any member of the household uses internet, 0 otherwise"

*Does the household own fixed telephone line at home?
g fixedphone = 2 - s7eq1a
label var fixedphone "1 = Household owns a fixed telephone line, 0 otherwise"

*Does any member of the household own desktop or laptop computers?
g pc = 2 - s7eq1c
label var pc "1 = Any member of the household owns desktop or laptop computers, 0 otherwise"



*Section 3D (Mortality)
*======================

*Any live birth in the last 12 months?
g birth = 1 if s3dq13==1
bys HID: egen birth12mo = max(birth)
recode birth12mo (. = 0)
label var birth12mo "1 = Any live birth in the household in the last 12 months, 0 otherwise"



*Section 6 (Agricultural household)
*==================================

g aghouse = 2 - s6q1
label var aghouse "1 = Any household member engaged in agriculture, 0 otherwise"

*Type of dwelling
recode s7aq1 (1 2 3 4 5 6 9 = 1) (7 8 10 11 = 0), gen(conventional)
label var conventional "1 = Conventional dwelling, 0 otherwise"

*Outer wall
recode s7fq1 (1 7 = 1) (2 3 8 9 = 2) (4 5 6 10 = 3), gen(wall)
label var wall "Main construction material of outer wall"
label define wall 1 "Mud bricks/earth, Landcrete" 2 "Wood, Metal sheet/slate/asbestos, Bamboo, Palm leaves/thatch(grass/ruffian)" 3 "Stone, Burnt bricks, Cement blocks/concrete, Other"
label val wall wall
tab wall, gen(wall)

*Floor
recode s7fq2 (1 = 1) (2 3 4 = 2)(5 6 7 8 9 = 3), gen(floor)
label var floor "Main construction material of floor"
label define floor 1 "Earth/mud" 2 "Cement/concrete, stone, burnt bricks" 3 "Wood, vinyl tiles, ceramic/porcelain/granite/marble tiles,terrazo/terrazo tiles, other"
label val floor floor
tab floor, gen(floor)

*Roof
recode s7fq3 (1 7 8 = 1)(2 4 6 = 2)(3 = 3)(5 9 = 4) , gen(roof)
label var roof "Main construction material of roof"
label define roof 1 "Mud/mud bricks/earth, bamboo, palm leaves/thatch(grass/ruffian)" 2 "Wood, slate/asbestos, roofing tile" 3 "Metal sheet" 4 "Concrete/Other"
label val roof roof
tab roof, gen(roof)

*Tenure
recode s7bq1 (1 = 1) (2 = 2) (3/6 = 3), gen(tenure)
label var tenure "Tenancy arrangement"
label define tenure 1 "Owning" 2 "Renting" 3 "Rent free, perching, squatting"
label val tenure tenure
tab tenure, gen(tenure)

*Number of rooms
g rooms = s7aq2
label var rooms "Number of rooms"

*Number of bedrooms
g bedrooms = s7aq3
label var bedrooms "Number of bedrooms"

*Main source of lighting
recode s7dq11 (1 2 5 = 1) (3 4 = 2) (7 = 3) (6 8 9 10 = 4), gen(lighting)
label var lighting "Main source of lighting"
label define lighting 1 "Electricity(mains), electricity(private generator),solar energy" 2 "Kerosene or gas lamp" 3 "Flashlight/torch" 4 "Candle, firewood, crop residue, other"
label val lighting lighting
tab lighting, gen(lighting)

*Source of drinking water
recode s7dq1a1 (1 2 3 4 = 1) (5 6 8 = 2) (9 10 = 3) (7 11/16 = 4), gen(water_drinking)
label var water_drinking "Main source of drinking water"
label define water1 1 "Pipe inside or outside dwelling, public tap" 2 "Bore-hole/pump/tube well, protected well, protected spring" 3 "Bottled or satchet water" 4 "Rain water, tanker, unprotected well or spring, river/stream,dugout/pond/canal/lake/dam, other"
label val water_drinking water1
tab water_drinking, gen(water_drinking)

*Water for general use
recode s7dq1a2 (1 2 3 4 = 1) (5 6 8 9 10 = 2) (7 11/16 = 3), gen(water_general)
label var water_general "Main source of water for general use"
label define water2 1 "Pipe inside or outside dwelling, public tap" 2 "Bore-hole/pump/tube well, protected well, protected spring, satchet water" 3 "Rain water, tanker, unprotected well or spring, river/stream,dugout/pond/canal/lake/dam, other"
label val water_general water2
tab water_general, gen(water_general)

*Main source of cooking fuel
recode s7dq13 (2 = 1) (3 = 2) (4 = 3) (1 5/10 = 4), gen(fuel)
label var fuel "Main source of cooking fuel"
label define fuel 1 "Wood" 2 "Charcoal" 3 "Gas" 4 "Electricity, kerosense , crop residue, sawdust, animal waste, other"
label val fuel fuel
tab fuel, gen(fuel)

*Type of toilet
recode s7dq16a (1 = 1) (2 = 2) (3 = 3) (4 = 4) (5/7 = 5), gen(toilet)
label var toilet "Type of toilet"
label define toilet 1 "No facility" 2 "WC" 3 "Pit latrine" 4 "KVIP" 5 "Bucket/pan, public toilet, other"
label val toilet toilet
tab toilet, gen(toilet)

*Solid waste disposal
rename s7dq14a solidwaste
tab solidwaste, gen(solidwaste)


*Merge with expenditure data for per capita expenditure
*======================================================

merge m:1 HID using "$expenditure\GHA_2013_E"
drop _me
merge m:1 HID using "$expenditure\13_GHA_2013_PINDEX.dta"
drop _merge
merge m:1 HID using "$expenditure\00_GHA_BASICINFO.dta"
drop _merge
g rpcexp = HHEXP_N*100/(pindex*eqsc)
g lnrpcexp = ln(rpcexp)

sort HID hhead
bys HID: keep if _n==1


save "$cleandata\survey", replace
