clear all
cd:"C:\Users\hp\OneDrive - University of Bristol\Documents"
capture log close
log using "Grp1DissTask.log", replace
insheet using "Stata Group task.csv"
browse
//Here we generate our new time variable
gen time=_n
drop if time<1491

//Here we calculate the log returns for SPDR and the nine sector using a loop
foreach v of varlist spyadjclose-xlyadjclose{
generate `v'LnDayRtn=(ln(`v'/`v'[_n-1]))*100
}
//Here we drop all the missing values
drop if spyadjcloseLnDayRtn==.

//For easy of communication and readability we set appropriate labels for all the newly generated columns


label variable spyadjcloseLnDayRtn "SPY Ln Day Return"

label variable xlbadjcloseLnDayRtn "XLB Ln Day Return"

label variable xleadjcloseLnDayRtn "XLE Ln Day Return "

label variable xlfadjcloseLnDayRtn "XLF Ln Day Return "

label variable xliadjcloseLnDayRtn "XLI Ln Day Return "

label variable xlkadjcloseLnDayRtn "XLK Ln Day Return "

label variable xlpadjcloseLnDayRtn "XLP Ln Day Return "

label variable xluadjcloseLnDayRtn "XLU Ln Day Return "

label variable xlvadjcloseLnDayRtn "XLV Ln Day Return "

label variable xlyadjcloseLnDayRtn "XLY Ln Day Return"

//Here we create the dummy variables for the percentiles that we need in order to run the regression in line with the parameters set out in the paper

//Lower 0.5%
egen PL05= pctile(spyadjcloseLnDayRtn), p(0.5)
gen D05Lower=0
replace D05Lower=1 if spyadjcloseLnDayRtn<=PL05

//Upper 0.5% 
egen PL995= pctile(spyadjcloseLnDayRtn), p(99.5)
gen D05upper=0
replace D05upper=1 if spyadjcloseLnDayRtn>=PL995

//Lower 1% 
egen PL1= pctile(spyadjcloseLnDayRtn), p(1)
gen D1Lower=0
replace D1Lower=1 if spyadjcloseLnDayRtn<=PL1

//Upper 1%

egen PL90= pctile(spyadjcloseLnDayRtn), p(90)
gen D1Upper=0
replace D1Upper=1 if spyadjcloseLnDayRtn>=PL90

//Lower 2%
egen PL2= pctile(spyadjcloseLnDayRtn), p(2)
gen D2Lower=0
replace D2Lower=1 if spyadjcloseLnDayRtn<=PL2

//Upper 2%
egen PL98= pctile(spyadjcloseLnDayRtn), p(98)
gen D2upper=0
replace D2upper=1 if spyadjcloseLnDayRtn>=PL98

//Next we will generate our CSSD and CSAD variables to be used for our regression

//CSSD

//Firstly we calculate our squared differences between log returns on nine sector ETFs and the SPDR. Using a foreach loop to simplify the process.

foreach v of varlist xlbadjcloseLnDayRtn - xlyadjcloseLnDayRtn {
gen `v'diffspysqrd = (`v'-spyadjcloseLnDayRtn)^2
}

//Now we generate part of the CSSD function to be used in the next steps to calculate the actual CSSD

egen CSSD_NUM = rowtotal(xlbadjcloseLnDayRtndiffspysqrd - xlyadjcloseLnDayRtndiffspysqrd)

gen CSSD = sqrt(CSSD_NUM/8)

//CSAD
foreach v of varlist xlbadjcloseLnDayRtn - xlyadjcloseLnDayRtn {
gen `v'diffspyabs = abs(`v'-spyadjcloseLnDayRtn)
}

//Using the same methods as above we formulate the CSAD

egen CSAD_NUM = rowtotal (xlbadjcloseLnDayRtndiffspyabs - xlyadjcloseLnDayRtndiffspyabs)

gen CSAD = CSAD_NUM/9

//Now we can regressions
//First we regress log returns in the lowest and highest 0.5% on SPDR returns.
//We do this for the the 1 and 2 percentile ranges as well
regress CSAD D05Lower D05upper
regress CSSD D05Lower D05upper


regress CSAD D1Lower D1Upper
regress CSSD D1Lower D1Upper


regress CSAD D2Lower D2upper�


120 regress CSSD D2Lower D2upper

///Finally we regress spyadjcloseLnDayRtn and spyadjcloseLnDayRtn^2 with CSAD and CSSD as our explanatory variables 
 
gen spyadjcloseLnDayRtnsqrd = (spyadjcloseLnDayRtn)^2

regress CSSD spyadjcloseLnDayRtn spyadjcloseLnDayRtnsqrd
regress CSAD spyadjcloseLnDayRtn spyadjcloseLnDayRtnsqrd
