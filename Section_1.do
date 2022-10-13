clear all
capture log close
log using "Section_1_replication_true.log", replace

cd "C:\Users\whisk\OneDrive\Documents\Bristol\Economics\Year 4\AED\Small Group Sessions\Week 2"

import excel "ETF Pricing Data for Section 1.xls", firstrow


//generate float values from string date variables
gen time = _n

//Here we calculate the log returns for SPDR and the nine sector using a loop

foreach i of varlist spy_adj_close-xly_adj_close{
	gen `i'_LnDayRtn = (ln(`i'/`i'[_n-1]))*100
	
}	

//Here we drop all the missing values
drop if spy_adj_close_LnDayRtn==.

//For easy of communication and readability we set appropriate labels for all the newly generated columns
label var time "Time"

foreach j of varlist spy_adj_close_LnDayRtn-xly_adj_close_LnDayRtn{
	local newname = substr("`j'", 1, 3)
	local uppername = upper("`newname'")
	label var `j' "`uppername' Log Day Returns"
	rename `j' `newname'_LnDayRtn
}

//Here we create the dummy variables for the percentiles that we need in order to run the regression in line with the parameters set out in the paper

//Lower 0.5%
egen PL05= pctile(spy_LnDayRtn), p(0.5)
gen D05Lower=0
replace D05Lower=1 if spy_LnDayRtn<=PL05

//Upper 0.5% 
egen PL995= pctile(spy_LnDayRtn), p(99.5)
gen D05upper=0
replace D05upper=1 if spy_LnDayRtn>=PL995

//Lower 1% 
egen PL1= pctile(spy_LnDayRtn), p(1)
gen D1Lower=0
replace D1Lower=1 if spy_LnDayRtn<=PL1

//Upper 1%

egen PL90= pctile(spy_LnDayRtn), p(90)
gen D1Upper=0
replace D1Upper=1 if spy_LnDayRtn>=PL90

//Lower 2%
egen PL2= pctile(spy_LnDayRtn), p(2)
gen D2Lower=0
replace D2Lower=1 if spy_LnDayRtn<=PL2

//Upper 2%
egen PL98= pctile(spy_LnDayRtn), p(98)
gen D2upper=0
replace D2upper=1 if spy_LnDayRtn>=PL98

//Next we will generate our CSSD and CSAD variables to be used for our regression

//CSSD

//Firstly we calculate our squared differences between log returns on nine sector ETFs and the SPDR. Using a foreach loop to simplify the process.

foreach v of varlist xlb_LnDayRtn - xly_LnDayRtn {
gen `v'diffspysqrd = (`v'-spy_LnDayRtn)^2
}

//Now we generate part of the CSSD function to be used in the next steps to calculate the actual CSSD

egen CSSD_NUM = rowtotal(xlb_LnDayRtndiffspysqrd - xly_LnDayRtndiffspysqrd)

gen CSSD = sqrt(CSSD_NUM/8)

//CSAD
foreach v of varlist xlb_LnDayRtn - xly_LnDayRtn {
gen `v'diffspyabs = abs(`v'-spy_LnDayRtn)
}

//Using the same methods as above we formulate the CSAD

egen CSAD_NUM = rowtotal (xlb_LnDayRtndiffspyabs - xly_LnDayRtndiffspyabs)

gen CSAD = CSAD_NUM/9

//Now we can regressions
//First we regress log returns in the lowest and highest 0.5% on SPDR returns.
//We do this for the the 1 and 2 percentile ranges as well
regress CSAD D05Lower D05upper
regress CSSD D05Lower D05upper


regress CSAD D1Lower D1Upper
regress CSSD D1Lower D1Upper


regress CSAD D2Lower D2upper


regress CSSD D2Lower D2upper

///Finally we regress spy_LnDayRtn and spy_LnDayRtn^2 with CSAD and CSSD as our explanatory variables 
 
gen spy_LnDayRtnsqrd = (spy_LnDayRtn)^2

regress CSSD spy_LnDayRtn spy_LnDayRtnsqrd
regress CSAD spy_LnDayRtn spy_LnDayRtnsqrd
