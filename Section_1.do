clear all
cd "/Users/harryavraamides/Desktop/OneDrive - University of Bristol/Third Year Modules/Dissertation"
capture log close
log using "Grp1DissTask.log", replace
insheet using "ETF_Pricing_Data_S1_Clean.csv"
browse
//Here we generate our new time variable
gen time=_n
drop if time<1491

//Here we calculate the log returns for SPDR and the nine sector using a loop
foreach v of varlist SPY_AdjClose-XLY_AdjClose{
generate `v'_LnDayRtn=(ln(`v'/`v'[_n-1]))*100
}
//Here we drop all the missing values
drop if SPY_AdjClose_LnDayRtn==.

//For easy of communication and readability we set appropriate labels for all the newly generated columns


label variable SPY_AdjClose_LnDayRtn "SPY Ln Day Return"

label variable XLB_AdjClose_LnDayRtn "XLB Ln Day Return"

label variable XLE_AdjClose_LnDayRtn "XLE Ln Day Return "

label variable XLF_AdjClose_LnDayRtn "XLF Ln Day Return "

label variable XLI_AdjClose_LnDayRtn "XLI Ln Day Return "

label variable XLK_AdjClose_LnDayRtn "XLK Ln Day Return "

label variable XLP_AdjClose_LnDayRtn "XLP Ln Day Return "

label variable XLU_AdjClose_LnDayRtn "XLU Ln Day Return "

label variable XLV_AdjClose_LnDayRtn "XLV Ln Day Return "

label variable XLY_AdjClose_LnDayRtn "XLY Ln Day Return"

//Here we create the dummy variables for the percentiles that we need in order to run the regression in line with the parameters set out in the paper

//Lower 0.5%
egen PL05= pctile(SPY_AdjClose_LnDayRtn), p(0.5)
gen D05Lower=0
replace D05Lower=1 if SPY_AdjClose_LnDayRtn<=PL05

//Upper 0.5% 
egen PL995= pctile(SPY_AdjClose_LnDayRtn), p(99.5)
gen D05upper=0
replace D05upper=1 if SPY_AdjClose_LnDayRtn>=PL995

//Lower 1% 
egen PL1= pctile(SPY_AdjClose_LnDayRtn), p(1)
gen D1Lower=0
replace D1Lower=1 if SPY_AdjClose_LnDayRtn<=PL1

//Upper 1%

egen PL90= pctile(SPY_AdjClose_LnDayRtn), p(90)
gen D1Upper=0
replace D1Upper=1 if SPY_AdjClose_LnDayRtn>=PL90

//Lower 2%
egen PL2= pctile(SPY_AdjClose_LnDayRtn), p(2)
gen D2Lower=0
replace D2Lower=1 if SPY_AdjClose_LnDayRtn<=PL2

//Upper 2%
egen PL98= pctile(SPY_AdjClose_LnDayRtn), p(98)
gen D2upper=0
replace D2upper=1 if SPY_AdjClose_LnDayRtn>=PL98

//Next we will generate our CSSD and CSAD variables to be used for our regression

//CSSD

//Firstly we calculate our squared differences between log returns on nine sector ETFs and the SPDR. Using a foreach loop to simplify the process.

foreach v of varlist XLB_AdjClose_LnDayRtn - XLY_AdjClose_LnDayRtn {
gen `v'diffspysqrd = (`v'-spy_LnDayRtn)^2
}

//Now we generate part of the CSSD function to be used in the next steps to calculate the actual CSSD

egen CSSD_NUM = rowtotal(XLB_AdjClose_LnDayRtndiffspysqrd - XLY_AdjClose_LnDayRtndiffspysqrd)

gen CSSD = sqrt(CSSD_NUM/8)

//CSAD
foreach v of varlist XLB_AdjClose_LnDay - XLY_AdjClose_LnDayRtn {
gen `v'diffspyabs = abs(`v'-spy_LnDayRtn)
}

//Using the same methods as above we formulate the CSAD

egen CSAD_NUM = rowtotal (XLB_AdjClose_LnDadiffspyabs - XLY_AdjClose_LnDayRtndiffspyabs)

gen CSAD = CSAD_NUM/9

//Now we can regressions
//First we regress log returns in the lowest and highest 0.5% on SPDR returns.
//We do this for the the 1 and 2 percentile ranges as well
regress CSAD D05Lower D05upper
regress CSSD D05Lower D05upper


regress CSAD D1Lower D1Upper
regress CSSD D1Lower D1Upper


regress CSAD D2Lower D2upper�


regress CSSD D2Lower D2upper

///Finally we regress spyadjcloseLnDayRtn and spyadjcloseLnDayRtn^2 with CSAD and CSSD as our explanatory variables 
 
gen spyadjcloseLnDayRtnsqrd = (spyadjcloseLnDayRtn)^2

regress CSSD spy_LnDayRtn spy_LnDayRtnsqrd
regress CSAD spy_LnDayRtn _LnDayRtnsqrd
