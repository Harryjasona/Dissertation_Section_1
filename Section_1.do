clear all
cd:"C:\Users\hp\OneDrive - University of Bristol\Documents"
capture log close
log using "Dissgrouptask.log", replace
insheet using "Stata Group task.csv"
browse
//generate time variables for dates as date values are string variables rather than numerical values.
gen time=_n
drop if time<1491
sort -date
//Calculating log returns for SPDR and the nine sector. Creating a lopp using the foreach function to make the calculations easy.
foreach v of varlist spyadjclose-xlyadjclose{
generate `v'LnDayRtn=(ln(`v'/`v'[_n-1]))*100
}
//dropping all the generated missing values
drop if spyadjcloseLnDayRtn==.

//Using "label" code to label the newly created variables label variable time "Time"

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

//The code below is run to get information on what are the smallest and largest values at different percentile levels in the data
sum spyadjcloseLnDayRtn, detail

_pctile spyadjcloseLnDayRtn, p(0.5, 1, 2, 98, 99, 99.5)

//Now in the Herding in ETFs paper the regression has dummy variables for the variables in lowest 3 percentiles of the data like (0.5%,1%,2%) and highest 3 percentiles of the data like (98%,99%,99.5%). The codes below will aim at creating those dummy variables.

//0.5% lower
egen PL05= pctile(spyadjcloseLnDayRtn), p(0.5)
gen D05Lower=0
replace D05Lower=1 if spyadjcloseLnDayRtn<=PL05

//0.5% upper
egen PL995= pctile(spyadjcloseLnDayRtn), p(99.5)
gen D05upper=0
replace D05upper=1 if spyadjcloseLnDayRtn>=PL995

//1% lower
egen PL1= pctile(spyadjcloseLnDayRtn), p(1)
gen D1Lower=0
replace D1Lower=1 if spyadjcloseLnDayRtn<=PL1

//1% upper

egen PL90= pctile(spyadjcloseLnDayRtn), p(90)
gen D1Upper=0
replace D1Upper=1 if spyadjcloseLnDayRtn>=PL90

//2% lower
egen PL2= pctile(spyadjcloseLnDayRtn), p(2)
gen D2Lower=0
replace D2Lower=1 if spyadjcloseLnDayRtn<=PL2

//2% upper
egen PL98= pctile(spyadjcloseLnDayRtn), p(98)
gen D2upper=0
replace D2upper=1 if spyadjcloseLnDayRtn>=PL98

//Next we will generate CSSD and CSAD variables

//CSSD

//first tep would be to calculate the squared differences between log returns on nine sector ETFs and the SPDR. We will use foreach to create a loop for the formula in order to simplify thrcalucaltions.

foreach v of varlist xlbadjcloseLnDayRtn - xlyadjcloseLnDayRtn {
gen `v'diffspysqrd = (`v'-spyadjcloseLnDayRtn)^2
}

//Now we will generate the numerator for the CSSD function using the rowtotal code to simplify the caluclation and after that we will generate the original CSSD variable itself

egen CSSD_NUM = rowtotal(xlbadjcloseLnDayRtndiffspysqrd - xlyadjcloseLnDayRtndiffspysqrd)

gen CSSD = sqrt(CSSD_NUM/8)

//CSAD
foreach v of varlist xlbadjcloseLnDayRtn - xlyadjcloseLnDayRtn {
gen `v'diffspyabs = abs(`v'-spyadjcloseLnDayRtn)
}

//Following the same process of calculation as CSSD, we code the following

egen CSAD_NUM = rowtotal (xlbadjcloseLnDayRtndiffspyabs - xlyadjcloseLnDayRtndiffspyabs)

gen CSAD = CSAD_NUM/9

//Now, we have to run four sets of regression. For the regression fromula where explanatory variables are the precentile dummy variables we run three sets of regression accounting for all the above considered percentile levels. The last set of regression is the one where the explanatory variables are spyadjcloseLnDayRtn and spyadjcloseLnDayRtn^2

//We first regress the log returns lying in the lowest 0.5 and highest 0.5 percentile of SPDR log returns. Within that we will have on regression with CSAD as the dependent variable and then CSSD as the dependent variable

regress CSAD D05Lower D05upper
regress CSSD D05Lower D05upper

//We now regress the log returns lying in the lowest 1 and highest 1 percentile of SPDR log returns. Within that we will have on regression with CSAD as the dependent variable and then CSSD as the dependent variable

regress CSAD D1Lower D1Upper
regress CSSD D1Lower D1Upper

////We now regress the log returns lying in the lowest 2 and highest 2 percentile of SPDR log returns. Within that we will have on regression with CSAD as the dependent variable and then CSSD as the dependent variable

regress CSAD D2Lower D2upper�


120 regress CSSD D2Lower D2upper

////We now regress the spyadjcloseLnDayRtn and spyadjcloseLnDayRtn^2 with CSAD and CSSD as the explanatory variables respectively
 
gen spyadjcloseLnDayRtnsqrd = (spyadjcloseLnDayRtn)^2

regress CSSD spyadjcloseLnDayRtn spyadjcloseLnDayRtnsqrd
regress CSAD spyadjcloseLnDayRtn spyadjcloseLnDayRtnsqrd
