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
//do file to prepare census data for poverty mapping
use "C:\POVMAP\glss7stata\g7PartA_1\g7sec1.dta" /*if _n<1000*/, clear

	
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
	
	
	
	//Generate number of women in the household
	egen num_female= sum((s1q2==2)), by(hid)
		lab var num_female "number of women in the household"
		
	//Generate number of men in the household
	egen num_male= sum((s1q2==1)), by(hid)
		lab var num_male "number of men in the household"
		
	//Marital status of the household head
    recode s1q6 (1 = 3) (2 = 2) (3 = 4) (4= 5) (5 = 6) (6 = 1), 
   gen head_maritalstatus = s1q6 if s1q3==1
 label define marital 1 "Never married" 2 "Informal/consensual union/living together" 3 "Married" 4 "Separated" 5 "Divorced" 6 "Widowed"
lab var head_maritalstatus "Marital status of the household head"
lab val head_maritalstatus marital

*Ethnicity of the household head
replace s1q13 = 97 if s1q12>=3 & s1q12<=16 
recode s1q13 (0/19=1) (20/22=2) (30=3) (40/48=4) (50/59=5) (60/69=6) (70/75=7) (80/82=8) (90/94=9) (97=10), gen(ethnicity)
label define ethnicity  1 "Akan"     2 "Ga"   3 "Ewe"  4 "Guan"  5 "Gurma"  6 "Mole-Dagbon"  7 "Grusi"  8 "Mande"  9 "Other" 10 "Foreigners"
label values ethnicity ethnicity
drop if ethnicity==32
gen head_ethnicity = ethnicity if s1q3==1
label var head_ethnicity "Ethnicity of the household head"
tab head_ethnicity, gen(head_ethnicity)
lab val head_ethnicity ethnicity

*Region of birth of the household head
recode s1q11 (96 97 98 = 11)
gen head_birthplace = s1q11 if s1q3==1
label var head_birthplace "Region of birth of the household head"
tab head_birthplace, gen(head_birthplace)


*Religion of the household head
gen head_religion = 1 if inrange(s1q10, 1,9)
replace head_religion = 2 if inrange(s1q10, 2,5)
replace head_religion = 3 if s1q10==6
replace head_religion = 4 if inrange(s1q10, 8,9)
lab val head_religion	"Religion of head of houshold"
label define head_religion 1 "No religion" 2 "Christian" 3 "Islam" 4 "Traditionalist/Other"

		
//Generate number of individuals in household
egen hhsize = count(pid), by(hid)
lab var hhsize "Number of members in HH"
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	