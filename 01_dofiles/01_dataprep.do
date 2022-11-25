* same as collapse
*ssc install groupfunction
**************************************
*This dofile prepares data from the census for
* small area estimation
*****************************************
use "C:\2021PHC\STATA_10%SAMPLE\defactopopn_10%_20221011d.dta" /*if _n<1000*/, clear

local tocollapse headsex female
// sex of hh head
tab a11d, nolab
gen headsex=(a11d==2) & a11c==1  

gen female= (a11d==2)  //share of females

groupfunction [aw=weight], mean(`tocollapse') rawsum(weight) by(region distcode)
*********************************
*what to consider adding
head married
head with post secondaryeducation
less than primary, primary 
head working






