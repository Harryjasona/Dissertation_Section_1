clear all
cd:"C:\Users\hp\OneDrive - University of Bristol\Documents"
capture log close
log using "Dissgrouptask.log", replace
insheet using "Stata Group task.csv"
browse
//generate time variables for dates as date values are string variables rather than numerical
values.//
gen time=_n
drop if time<1491
sort -date
//Calculating log returns for SPDR and the nine sector. Creating a lopp using the foreach
function to make the calculations easy.//
foreach v of varlist spyadjclose-xlyadjclose{
generate `v'LnDayRtn=(ln(`v'/`v'[_n-1]))*100
}
//dropping all the generated missing values//
drop if spyadjcloseLnDayRtn==.

//Using "label" code to label the newly created variables//
label variable time "Time"

label variable spyadjcloseLnDayRtn "SPY Ln Day Return"

label variable xlbadjcloseLnDayRtn "XLB Ln Day Return"

label variable xleadjcloseLnDayRtn "XLE Ln Day Return "

label variable xlfadjcloseLnDayRtn "XLF Ln Day Return "

label variable xliadjcloseLnDayRtn "XLI Ln Day Return "

label variable xlkadjcloseLnDayRtn "XLK Ln Day Return "

label variable xlpadjcloseLnDayRtn "XLP Ln Day Return "

label variable xluadjcloseLnDayRtn "XLU Ln Day Return "
36
37 label variable xlvadjcloseLnDayRtn "XLV Ln Day Return "
38
39 label variable xlyadjcloseLnDayRtn "XLY Ln Day Return"
40
41 //The code below is run to get information on what are the smallest and largest values at
different percentile levels in the data//
42 sum spyadjcloseLnDayRtn, detail
43
44 _pctile spyadjcloseLnDayRtn, p(0.5, 1, 2, 98, 99, 99.5)
45
46 //Now in the Herding in ETFs paper the regression has dummy variables for the variables in lowest
3 percentiles of the data like (0.5%,1%,2%) and highest 3 percentiles of the data like
(98%,99%,99.5%). The codes below will aim at creating those dummy variables.//
47
48 //0.5% lower//
49 egen PL05= pctile(spyadjcloseLnDayRtn), p(0.5)
50 gen D05Lower=0
51 replace D05Lower=1 if spyadjcloseLnDayRtn<=PL05
52
53 //0.5% upper//
54 egen PL995= pctile(spyadjcloseLnDayRtn), p(99.5)
55 gen D05upper=0
56 replace D05upper=1 if spyadjcloseLnDayRtn>=PL995
57
58 //1% lower//
59 egen PL1= pctile(spyadjcloseLnDayRtn), p(1)
60 gen D1Lower=0
61 replace D1Lower=1 if spyadjcloseLnDayRtn<=PL1
62
63 //1% upper// 
Stata Diss group (2) - Printed on 13/10/2022 13:08:36
Page 2
64 egen PL90= pctile(spyadjcloseLnDayRtn), p(90)
65 gen D1Upper=0
66 replace D1Upper=1 if spyadjcloseLnDayRtn>=PL90
67
68 //2% lower//
69 egen PL2= pctile(spyadjcloseLnDayRtn), p(2)
70 gen D2Lower=0
71 replace D2Lower=1 if spyadjcloseLnDayRtn<=PL2
72
73 //2% upper//
74 egen PL98= pctile(spyadjcloseLnDayRtn), p(98)
75 gen D2upper=0
76 replace D2upper=1 if spyadjcloseLnDayRtn>=PL98
77
78 //Next we will generate CSSD and CSAD variables//
79
80 //CSSD//
81
82 //first tep would be to calculate the squared differences between log returns on nine sector ETFs
and the SPDR. We will use foreach to create a loop for the formula in order to simplify thr
calucaltions.//
83
84 foreach v of varlist xlbadjcloseLnDayRtn - xlyadjcloseLnDayRtn {
85 gen `v'diffspysqrd = (`v'-spyadjcloseLnDayRtn)^2
86 }
87
88 //Now we will generate the numerator for the CSSD function using the rowtotal code to simplify
the caluclation and after that we will generate the original CSSD variable itself//
89
90 egen CSSD_NUM = rowtotal(xlbadjcloseLnDayRtndiffspysqrd - xlyadjcloseLnDayRtndiffspysqrd)
91
92 gen CSSD = sqrt(CSSD_NUM/8)
93
94 //CSAD//
95 foreach v of varlist xlbadjcloseLnDayRtn - xlyadjcloseLnDayRtn {
96 gen `v'diffspyabs = abs(`v'-spyadjcloseLnDayRtn)
97 }
98
99 //Following the same process of calculation as CSSD, we code the following//
100
101 egen CSAD_NUM = rowtotal (xlbadjcloseLnDayRtndiffspyabs - xlyadjcloseLnDayRtndiffspyabs)
102
103 gen CSAD = CSAD_NUM/9
104
105 //Now, we have to run four sets of regression. For the regression fromula where explanatory
variables are the precentile dummy variables we run three sets of regression accounting for all
the above considered percentile levels. The last set of regression is the one where the
explanatory variables are spyadjcloseLnDayRtn and spyadjcloseLnDayRtn^2//
106
107 //We first regress the log returns lying in the lowest 0.5 and highest 0.5 percentile of SPDR log
returns. Within that we will have on regression with CSAD as the dependent variable and then CSSD
as the dependent variable//
108
109 regress CSAD D05Lower D05upper
110 regress CSSD D05Lower D05upper
111
112 //We now regress the log returns lying in the lowest 1 and highest 1 percentile of SPDR log
returns. Within that we will have on regression with CSAD as the dependent variable and then CSSD
as the dependent variable//
113
114 regress CSAD D1Lower D1Upper
115 regress CSSD D1Lower D1Upper
116
117 ////We now regress the log returns lying in the lowest 2 and highest 2 percentile of SPDR log
returns. Within that we will have on regression with CSAD as the dependent variable and then CSSD
as the dependent variable//
118
119 regress CSAD D2Lower D2upper 
Stata Diss group (2) - Printed on 13/10/2022 13:08:36
Page 3
120 regress CSSD D2Lower D2upper
121
122 ////We now regress the spyadjcloseLnDayRtn and spyadjcloseLnDayRtn^2 with CSAD and CSSD as the
explanatory variables respectively//
123
124 gen spyadjcloseLnDayRtnsqrd = (spyadjcloseLnDayRtn)^2
125
126 regress CSSD spyadjcloseLnDayRtn spyadjcloseLnDayRtnsqrd
127 regress CSAD spyadjcloseLnDayRtn spyadjcloseLnDayRtnsqrd
