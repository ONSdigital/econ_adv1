*** Earnings and low pay: distributions and estimates from the Labour Force Survey ***

*** Description: STATA code used for distributional earnings analysis of the LFS and low pay estimates ***
*** Authors: Economic Advice and Analysis, Office for National Statistics ***
*** Contact: economic.advice@ons.gov.uk ***
*** Note: The code has been used for analysis in Q4, 2016 and may be updated and refined for future time periods ***



/* 
Each local stands for each stage of the code.
i.e. local 1 = 1 will run the first stage of the code. 
1. 
Setup 
Regression 
Nearest 

2.
2nd jobs setup 
2nd jobs regression 
Nearest 2ndjobs 
 
3 = 1p table 
4 = 16+ below NWM 
5 = Final tables 
*/  



/* The locals: name, location, and folder refer to three folders the data would save in. For example 'organisation' is a folder inside the folder 'name'. */
global name = "name"
global location = "organisation"  
global folder = "folder"

/* global time refers to the year and quarter please keep this in line with global time or you may experience mislabelling and issues within the code */ 
global time = "2016Q4"

/* The lfstime states the time period we are looking for, if you want to look at different time codes adjust this. For example: 201610 refers to 2016 Q4, 201607 is 2016 Q3, 201604 is 2016 Q2, and 201601 refers to 2016 Q1  */ 
global lfstime = "201610"

/* Datasets are not saved by this code. Only the Excel files are saved. See line 2757 onwards */ 



forvalues i = 1/5 {
clear all
local 1 = "`i'"
 
if "`1'" == "1" {
*** Main Jobs- Create jobs databse ***
/* Setting up the LFS dataset: 
FOR ${time}, we updated piwt14 to piwt16 and to piwt17 
levqual - levqul15 
hiqual - hiqual15 
sc2kmmj - sc10mmj 
eth01 - ethukeul  

This is where we load our LFS data in from, ${time}10 ${time}10 q corresponds to the start date and the end of the date in Quarters. 
Note: for code to run, data must be saved in this format and loaded as a dataset containing the time periods required.
Previous analysis focussed on ${time} Q4 here, so that is the end and start date. 
Other listed variables are those used in the analysis. */

clear all
set more off, perm 
cd "V:\Programs\"
lfs ${lfstime} ${lfstime} q piwt17 pwt17 age sex marsta hiqual15 govtor ethukeul levqul15 discurr13 hourpay grsswk bushr pothr hrrate ftptwk mpnr02 inde07m inds07m empmon netwk sc10mmj ernfilt usgrs99 grsprd netprd everot jobtyp cryox7 natox7 apprcurr fled10 flexw7

/* Once the data is loaded in, tempoarily save it as it's own dataset */ 
save "V:\Users\\${name}\\${location}\\${folder}\low_pay_16.dta", replace

/* Select only cases with a postive income weight and removing cases without */
keep if piwt17 > 0

/* Converting negative values to missing values */
mvdecode _all, mv(-9 -8)

/* Creating new variables by creating dummy variables. 
e.g. 1 if you are UK born and 2 if you're Non-UK born */
gen cryox7a=.
replace cryox7a=1 if cryox7==926
replace cryox7a=2 if cryox7!=926 & cryox7!=.
label define ukelse 1 "UK born" 2 "Non-UK born"
label values cryox7a ukelse
tab cryox7a

gen natox7a=.
replace natox7a=1 if natox7==926
replace natox7a=2 if natox7!=926 & natox7!=.
label values natox7a ukelse
tab natox7a

gen eth01a=. 
replace eth01a=1 if ethukeul==1
replace eth01a=2 if ethukeul!=1 & ethukeul!=. 
label define whitenonwhite 1 "White" 2 "Non-White" 
label values eth01a whitenonwhite 
tab eth01a

gen discurr13a=.
replace discurr13a=1 if inrange(discurr13, 1, 3)
replace discurr13a=2 if discurr13==4
label define disab 1 "Disability" 2 "No Disability"
label values discurr13a disab
tab discurr13a

gen levqul15a=.
replace levqul15a=1 if inrange(levqul15, 1, 6)
replace levqul15a=2 if levqul15==7
label define qual 1 "Have Qualification" 2 "No qualification"
label values levqul15a qual
tab levqul15a

/* Set hrrate=996-999 as missing values as not recognised as such by the system */
mvdecode hrrate, mv(996 997 998 999) 

/* Compute variables required in the regression analysis and tidy up ftptwk, sex and jobtyp so that are all 0 or 1 */
gen lhe = ln(hourpay)
gen lwe = ln(grsswk) 
gen lhr = ln(hrrate)
gen agesq = age*age
gen pt = ftptwk-1
gen female = sex-1
gen imperm = jobtyp - 1

/* Code minimum and living wage agebands into binary variables, ready for regression 
for ${time}, due to different agebands and the NLW, we need to change the age groups */
gen age1 =0
replace age1=1 if age < 18

gen age2 =0
replace age2=1 if age >= 18 & age <= 20

gen age3 =0
replace age3=1 if age >= 21 & age <=24

gen age4 =0 
replace age4=1 if age >=25

gen sernum = _n
gen const_ =1

/* If ln of hrrate is <0 (i.e. hrrate <£1/hr) set it to missing because it is implausible */
replace lhr=. if lhr < 0

/* Create quadratic term */ 
bysort date: egen lhe_1 = mean(lhe)
gen lhsq2 = (lhe - lhe_1)^2

/* Recode categorical variables to be used in the regression into binary, starting with miscellaneous variables, then variables relating to educational qualifications, regions, occupation and industry */
gen married=.
local num1 = "2 6"
forvalues i = 1/2 {
local x = word("`num1'", `i') 
replace married=1 if marsta==`x'
}
local num0 = "1 3 4 5 7 8 9" 
forvalues i = 1/7 {
local x = word("`num0'", `i') 
replace married=0 if marsta == `x' 
}
gen size=.
replace size=1 if inrange(mpnr02, 5, 9) 
replace size=0 if inrange(mpnr02, 1, 4)

gen ltwk=.
replace ltwk = 1 if grsprd == 90
replace ltwk = 0 if grsprd != 90

gen addtbp=.
replace addtbp=1 if ernfilt==1
replace addtbp=0 if ernfilt==2
replace addtbp=0 if ernfilt==3
replace addtbp=0 if ernfilt==.

gen usgrs=.
replace usgrs=1 if usgrs99==1| usgrs99==-.
replace usgrs=0 if inrange(usgrs99, 2, 3)

gen lusgrs = usgrs*lhe

gen otwork=.
replace otwork=1 if everot==1
replace otwork=0 if everot==2

/* Recode qualifications variables 
Brackets represent a range, so recode 1 to 9 equal to 1, to shorten the code */
recode hiqual15 (1/9 = 1) (10/85 =0), gen(q1)
recode hiqual15 (10/26=1)  (1/9=0)  (27/85=0), gen(q2)
recode hiqual15 (27/45=1)  (1/26=0)  (46/85=0), gen(q3)
recode hiqual15 (46/58=1)  (1/45=0)  (59/85=0), gen(q4)
recode hiqual15 (59/83=1)  (1/58=0)  (84/85=0), gen(q5)
recode hiqual15 (84/85=1)  (1/83=0), gen(q6)

/* Recode region variables */
recode govtor (1/2=1)  (3/20=0), gen(reg1)
recode govtor (3/5=1)  (1/2=0)  (6/20=0), gen(reg2)
recode govtor (6/8=1)  (1/5=0)  (9/20=0), gen(reg3)
recode govtor (9=1)  (1/8=0)  (10/20=0), gen(reg4)
recode govtor (10/11=1)  (1/9=0)  (12/20=0), gen(reg5)
recode govtor (12=1)  (1/11=0)  (13/20=0), gen(reg6)
recode govtor (13/14=1)  (1/12=0)  (15/20=0), gen(reg7)
recode govtor (15=1)  (1/14=0)  (16/20=0), gen(reg8)
recode govtor (16=1)  (1/15=0)  (17/20=0), gen(reg9)
recode  govtor (17=1)  (1/16=0)  (18/20=0), gen(reg10)
recode govtor (18/19=1)  (1/17=0)  (20=0), gen(reg11)
recode  govtor (20=1)  (1/19=0), gen(reg12)

/* Recode occupation variables */
recode  sc10mmj (1=1)  (2/9=0), gen(soc1)
recode  sc10mmj (2=1)  (1=0)  (3/9=0), gen(soc2)
recode sc10mmj (3=1)  (1/2=0)  (4/9=0), gen(soc3)
recode sc10mmj (4=1)  (1/3=0)  (5/9=0), gen(soc4)
recode sc10mmj  (5=1)  (1/4=0)  (6/9=0), gen(soc5)
recode sc10mmj  (6=1)  (1/5=0)  (7/9=0), gen(soc6)
recode sc10mmj (7=1)  (1/6=0)  (8/9=0), gen(soc7)
recode  sc10mmj (8=1)  (1/7=0)  (9=0), gen(soc8)
recode sc10mmj (9=1)  (1/8=0), gen(soc9)

/* Recode industry variables */
recode inde07m (1=1)  (2/9=0), gen(ind1)
recode inde07m (2=1)  (1=0)  (3/9=0), gen(ind2)
recode inde07m (3=1)  (1/2=0)  (4/9=0), gen(ind3)
recode  inde07m (4=1)  (1/3=0)  (5/9=0), gen(ind4)
recode  inde07m (5=1)  (1/4=0)  (6/9=0), gen(ind5)
recode inde07m  (6=1)  (1/5=0)  (7/9=0), gen(ind6)
recode  inde07m  (7=1)  (1/6=0)  (8/9=0), gen(ind7)
recode inde07m  (8=1)  (1/7=0)  (9=0), gen(ind8)
recode  inde07m (9=1)  (1/8=0), gen(ind9)

/* Assign a value of 0 to a new variable 'period' for cases in which pay period is less than weekly and a value of 1 to other cases */
gen period = .
foreach var of varlist grsprd netprd {
local gnum "2 3 4 5 7 8 9 10 13 26 52 95 97"
forvalues i = 1/13 { 
local x = word("`gnum'", `i')
replace period = 0 if `var' == `x'
}
}
foreach var of varlist grsprd netprd {
local gnum "1 90"
forvalues i = 1/2 {
local x = word("`gnum'", `i')
replace period=1 if `var' == `x'
}
}

/* Create ageband variable: update if minimum age bands change */
gen ageband=.
replace ageband=0 if age < 18
replace ageband=1 if age >= 18 & age <=20
replace ageband=2 if age >= 21 & age < 25
replace ageband=3 if age >=25
label define bands 0 "<18" 1 "18-20" 2 "21-24" 3 "25+"
label values ageband bands
tab ageband

/* Save the dataset to allow futher stages without re-running the set-up */
save "V:\Users\\${name}\\${location}\\${folder}\prep16.dta", replace
erase "V:\Users\\${name}\\${location}\\${folder}\low_pay_16.dta"

/* Outlier processing: runs as a loop until all outliers are dealt with */
/* Outputs:  pre_imputation.dta   The quarterly LFS dataset with outliers processed.  This dataset is now ready for nearest neighbour imputation.
        outlier_report.dta        A report on outlier processing undertaken by this code, with details of how each outlier observation has been processed (serial number), and at at which stage.    
        graphs ga`j' j=1,......   These are Normal-PP plots of Regression Studentized Residuals, j corresponds to the loop number.   
        graphs gb`j' j=1,.....    These are scatters of the standardized predicted value from the regression versus the studentized regression residuals.
                                  Observations with a Cook's distance>0.02 are in red.  j corresponds to the loop number.       
								  
The code is a regression run as many times as necessary on a loop which has the form:  
ln(hrrate(o)) = b0 + b1.ln(hourpay(o)) + b2.ln(hourpay(o)-mean(hourpay))^2 + linear combination of (beta * other covariates(o)) + e(o) for observations o=1,..,n
After each regression, Cook's distance is calculated for each observation.  This is used to identify outlier observations, by the criterion Cook's distance>0.02.

The main loop is constructed using two local macros.  The macro i checks how many outliers there are as a result of each execution of the loop.  The loop stops when there are no more 
observations with Cook's distance >0.02.  This is why top of the loop has a (while i>0) { } command.  Each time the loop executes, another local macro called j increments by 1 (starting
from 1). The maximal value of j is determined by the program because the loop is repeated, removing (by setting certain variable values to missing) observations or recalculating data
values until there are no more outliers. j allows the program to keep track of how many times the loop has executed.  It is also used to label variables that change on each iteration 
of the loop.  This includes the Cook's distances, which are labelled cj, the hrrate, hourpay and grsswk LFS variables which are actually labelled hrratej and hourpayj and grsswkj, and
the natural logarithms of the hrratej and grsswkj variables, which are labelled lhrj and lhej respectively. This is also true of of the squared difference of lhe from the mean, labelled 
lhsq2j.  Another local macro, k, equal to j+1, is used at the end of the loop to update the values of lhrj, lhej and lhsq2j for the next iteration of the loop.  

Before entering the loop the names of hrrate, hourpay, grsswk, lhr, lhe and lhsq2 are initialised as hrrate1, hourpay1, grsswk1, lhr1, lhe1, lhsq21 ready for the first round of the 
loop in which j=1.

Each time the loop exectues and the regression is run, the identified outlier observations are processed according to certain rules, depending on the characteristics of each.  A flagj
variable is constructed, the values of which show the outlier's characteristic. The flagj value therefore identifies the type of outlier, which determines the way in which the observation
is processed.  A new flagj variable is constructed on each execution of the loop, which is why the flagj variable has its name indexed by j. The flags and the appropriate processing are
as follows:
flagj = 1:  Cook's distance > 0.02 and 10 x scaling error detected in hrrate (hrrate between 9 and 11 times hourpay).  Response:  replace hrrate with hrrate/10.
flagj = 2:  Cook's distance > 0.02 and 100 x scaling error detected in hrrate (hrrate between 90 and 11- times hourpay).  Response:  replace hrrate with hrrate/100.
flagj = 3:  Cook's distance > 0.02 and netwk>grsswk.  (grsswk should be greater than netwk).  hourpay is usually constructed as grsswk/(bushr+pothr) or grsswk/bushr.
            Response:  replace grsswk with netwk and recalculate hourpay as netwk/bushr or netwk(bushr+pothr).           
flagj = 4:  Cook's distance >0.02, hourpay outside 1 and 99 percentile marginal distribution of hourpay,  hrrate inside 1 and 99 percentile marginal distribution of hrrate.
            and none of the flag values above.  Response:  Set hourpay = missing. 
flagj = 5:  Cook's distance >0.02, hrrate outside 1 and 99 percentile marginal distribution of hrrate,  hourpay inside 1 and 99 percentile marginal distribution of hourpay.
            and none of the flag values above.  Response:  Set hrrate = missing. 
flagj = 6:  Cook's distance >0.02, hrrate outside 1 and 99 percentile marginal distribution of hrrate, hourpay outside of 1 and 99 percentile marginal distribution of hourpay,
            and none of the flag values above.  Response: Set hrrate = missing and hourpay = missing.
Flagj = 7:  Outliers have cooks > 0.02 and no obvious other problems
Flagj = 8:  Outliers have cooks missing and hrrate lies outside the hrrate is outside the 1-99 percentile range.

When the flag values get assigned, the response is actually first calculated in variables called hrrate_hat and hourpay_hat.  This allows the responses to be compared with the outlier
values.  All of the outlier observations get saved into a separate dataset called imputed`j'.dta.   At the end of loop, the imputedj.dta files get appended together to generate a file
called outlier_report.dta, and the individual imputedj.dta files are then erased as they are no longer needed.  outlier_report.dta contains all of the identified outlier observations, with
variables relevant for checking whether the actions taken in response to the identified outlier are reasonable. For each outlier there are: observation serial numbers (sernum), original
LFS values of hrrate, hourpay, grsswk, netwk, bushr, pothr, 1 and 99 percentile bounds for marginal distributions of hrrate and hourpay on the loop at which the observation was identified
to be an outlier.  Note that these bounds will change with j because the dataset changes with j as observation values are set to missing or recalculated according to the flags. 
outlier_report.dta also contains the variables flaglab and action_taken_lab, which use value labels to describe the meaning of the flagj value and the response taken to amend the data. 
Of course, the dataset changes with each j, the outlier status of some observations changes with each j (this is how the program works).  The flagj variable shows you on which iteration of
the loop the observation was identified as an outlier.  The observation was first identified as an outlier at the loop number equal to the lowest j in outlier_report.dta for which flagj of
a particular observation is non-empty.  Note that an observation may be identified as an outlier more than once, if the first treatment does not result in a Cook's distance less than 0.02
on the next round of regression.   This will be evident if the same sernum is present on more than one row of outlier_report.dta.

The program produces graphs on each iteration of the main loop, which allow you to see how the outlier processing went on each iteration of the loop .  These are called gaj and gbj.
gaj is the PP-Normal plot of the studentized resisduals from the regression.  gbj is the studentized residuals plotted against the standardized predicted values from the regression. On the
latter outlier observations are shown in bright red.

When there are no more outliers, the main loop stops. The dataset with all outliers processed according to the flags is saved as pre_imputation.dta. This is nearly ready for nearest neighbour 
imputation. */

clear all
set more off 
cd "V:\Users\\${name}\\${location}\\${folder}"
graph drop _all
use "V:\Users\\${name}\\${location}\\${folder}\prep16.dta"

local j = 1
local i = _N

rename lhr lhr1
rename lhe lhe1
rename lhsq2 lhsq21
rename hrrate hrrate1
rename hourpay hourpay1
rename grsswk grsswk1
gen maxloop=.

while (`i'>0) {	
	display "i="`i'
	display "j="`j'
	
	regress lhr`j' lhe`j' lhsq2`j' addtbp age agesq empmon female ind1 ind2 ind3 ind4 ind5 ind6 ind7 ind9 ltwk married pt q1 q2 q3 q5 q6 period reg1 reg10 reg11 reg12 reg2 reg3 reg4 reg5 reg6 reg7 reg9 size soc1 soc2 soc3 soc5 soc6 soc7 soc8 soc9 usgrs age1 age2 age3 imperm otwork lusgrs
	predict cooks`j', cooksd
	
	/* Standardized predicted value. */
	predict y_hat`j'
	egen y_hat_bar=mean(y_hat`j')
	egen sd_y_hat = sd(y_hat`j')
	gen stan_y_hat=(y_hat`j' - y_hat_bar)/sd_y_hat
	label variable stan_y_hat "Standardized predicted value"
	
	/* Studentized residuals. */
	predict e_hat_student`j', rstudent
	/* PP-normal plots of studentized residuals of lhr. */
	local gn=`j'-1
	pnorm e_hat_student`j', name(ga`j-1')
	
	/* Scatter plot of studentized residuals against standardized predicted value
	graph twoway (scatter e_hat_student`j' stan_y_hat if cooks`j'<=0.02) (scatter e_hat_student stan_y_hat if cooks`j'>0.02), ysc(r(0, 20)) xsc(r(-7.5, 7.5)) name(gb`j-1') */
	graph twoway (scatter e_hat_student`j' stan_y_hat if cooks`j'<=0.02) (scatter e_hat_student`j' stan_y_hat if cooks`j'>0.02, mcolor(red)), legend(label(1 "Cook's dist.<=0.02") label(2 "Cook's dist>0.02")) name(gb`j-1')
	

	/* Drop the graphing variables on each loop iteration. */
	drop y_hat_bar sd_y_hat stan_y_hat
	
	egen hrrate_p1_a`j' = pctile(hrrate`j') if cooks`j'<=0.02, p(1) 
	egen hrrate_p99_a`j'= pctile(hrrate`j') if cooks`j'<=0.02 , p(99) 
	egen hourpay_p1_a`j' = pctile(hourpay`j') if cooks`j' <=0.02, p(1) 
	egen hourpay_p99_a`j'= pctile(hourpay`j') if cooks`j' <= 0.02 , p(99) 
	
	egen hrrate_p1_`j'=mean(hrrate_p1_a`j')
	egen hrrate_p99_`j'=mean(hrrate_p99_a`j')
	egen hourpay_p1_`j'=mean(hourpay_p1_a`j')
	egen hourpay_p99_`j'=mean(hourpay_p99_a`j')
	
	drop hrrate_p1_a`j' hrrate_p99_a`j' hourpay_p1_a`j' hourpay_p99_a`j'
	
	gen flag`j'=.
	gen hrrate_hat=.
	gen grsswk_hat=.
	gen hourpay_hat=.
	
	gen hourpay_10_lower = 9*hourpay`j'
	gen hourpay_10_upper = 11*hourpay`j'
	gen hourpay_100_lower = 90 * hourpay`j'
	gen hourpay_100_upper = 110 * hourpay`j'
	
	/* Flagj = 1:  Approx 10-fold scaling errors in hrrate. */
	replace hrrate_hat=hrrate`j'/10	  if ((cooks`j'>0.02) & (cooks`j' !=.)&(hrrate`j'>hourpay_10_lower) & (hrrate`j'<hourpay_10_upper))
	replace flag`j'=1 if ((cooks`j'>0.02) & (cooks`j' !=.)&(hrrate`j'>hourpay_10_lower) & (hrrate`j'<hourpay_10_upper))
	
	/* Flagj = 2:  Approx 100-fold scaling errors in hrrate. */
	replace hrrate_hat=hrrate`j'/100 if ((cooks`j'>0.02)& (cooks`j' !=.)&(hrrate`j'>hourpay_100_lower) & (hrrate`j'<hourpay_100_upper)) 
	replace flag`j'=2 if ((cooks`j'>0.02) & (cooks`j' !=.)&(hrrate`j'>hourpay_100_lower) & (hrrate`j'<hourpay_100_upper))
	drop hourpay_10_lower hourpay_10_upper hourpay_100_lower hourpay_100_upper
	
	/* Flagj = 3: Netwk>grsswk => use netwk instead. */
	replace grsswk_hat=netwk if ((cooks`j'>0.02)&(cooks`j' !=.)&(grsswk`j'<netwk))
	replace flag`j'=3 if ((cooks`j'>0.02) & (cooks`j' !=.) & (grsswk`j'<netwk))
	replace hourpay_hat = grsswk_hat/(pothr+bushr) if ((flag`j'==3) & (pothr >= 0 & pothr <= 97 & bushr >= 1 & bushr <= 97))
	replace hourpay_hat = grsswk_hat/(bushr) if ((flag`j'==3)&(pothr < 0 | pothr > 97) & ( bushr >= 1 & bushr <= 97))
	
	/* Flagj = 4: Outliers with hrrate outside, hourpay inside of 1-99 percentile range (and none of the previous flags apply). */
	replace hrrate_hat= . if ((cooks`j'>0.02)& (cooks`j' !=.)& (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3) & (hrrate`j'<hrrate_p1_`j' | hrrate`j'>hrrate_p99_`j') & (hourpay`j'>hourpay_p1_`j' & hourpay`j'<hourpay_p99_`j'))
	replace flag`j'=4 if ((cooks`j'>0.02)& (cooks`j' !=.)& (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3) &(hrrate`j'<hrrate_p1_`j' | hrrate`j'>hrrate_p99_`j') & (hourpay`j'>hourpay_p1_`j' & hourpay`j'<hourpay_p99_`j'))
	
	/* Flagj = 5: Outliers with hourpay outside, hrrate inside of 1-99 percentile range (and none of the previous flags apply). */
	replace hourpay_hat = . if ((cooks`j'>0.02)& (cooks`j' !=.)& (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3)& (flag`j'!=4) & (hourpay`j'<hourpay_p1_`j' | hourpay`j'>hourpay_p99_`j') & (hrrate`j'>hrrate_p1_`j' & hrrate`j'<hrrate_p99_`j')  )
	replace flag`j'=5 if ((cooks`j'>0.02)& (cooks`j' !=.)& (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3)& (flag`j'!=4) &(hourpay`j'<hourpay_p1_`j' | hourpay`j'>hourpay_p99_`j') & (hrrate`j'>hrrate_p1_`j' & hrrate`j'<hrrate_p99_`j')  )
	
	/* Flagj = 6:  Outliers with hrrate outside of 1-99 percentile range AND hourpay outside of 1-99 percentile range (and none of previous flags apply). */
	replace flag`j'=6 if ((cooks`j'>0.02 & cooks`j' !=.) & (hourpay`j'<hourpay_p1_`j' | hourpay`j'>hourpay_p99_`j') & (hrrate`j'<hrrate_p1_`j' | hrrate`j'>hrrate_p99_`j') & (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3) & (flag`j'!=4) & (flag`j'!=5))
	replace hrrate_hat = . if flag`j'==6
	replace hourpay_hat = . if flag`j'==6
	
	/* Flagj = 7: Outliers have cooks > 0.02 and no obvious other problems */
	replace flag`j'=7 if ((cooks`j'>0.02 & cooks`j' !=.) & (flag`j' !=1) &(flag`j' !=2) & (flag`j' !=3) & (flag`j' !=4) & (flag`j' !=5)  & (flag`j' !=6))
	gen hrrate_storage`j'= hrrate`j'
	replace hrrate_hat = . if flag`j'==7
	
	/* Flagj = 8: Outliers have cooks missing and hrrate lies outside the hrrate is outside the 1-99 percentile range. */
	replace flag`j'=8 if ((cooks`j'==.) & (flag`j' !=1) &(flag`j' !=2) & (flag`j' !=3) & (flag`j' !=4) & (flag`j' !=5)  & (flag`j' !=6) & (flag`j'!=7) & (hrrate`j'<hrrate_p1_`j' | hrrate`j'>hrrate_p99_`j'))
	/* gen hrrate_storage`j'= hrrate`j' */
	replace hrrate_hat = . if flag`j'==8
	
	preserve
	keep if (cooks`j'>0.02 ) & (cooks`j' !=.)
	keep sernum hrrate`j' hourpay`j' hrrate_hat hourpay_hat hrrate_storage`j' grsswk`j' netwk bushr pothr grsswk_hat flag*  cooks`j'  hrrate_p1_`j' hrrate_p99_`j' hourpay_p1_`j' hourpay_p99_`j'
	local i = _N 	
	save "imputed`j'.dta", replace	
	restore	
		
	/* Put the new fitted values into the variables for the regression in the next step. */
	local k=`j'+1
	gen hrrate`k'=hrrate`j'
	gen grsswk`k'=grsswk`j'
	gen hourpay`k'=hourpay`j'
	
	/* Flags 1,2,4, 6, 7 and 8 indicate that hrrate should be updated in the next iteration. */
	replace hrrate`k' = hrrate_hat if (flag`j'==1 | flag`j'==2 | flag`j'==4| flag`j'==6| flag`j'==7 | flag`j'==8  )
	
	/* Flags 3 and 5 indicates that hourpay should be updated in the next iteration, and grsswk gets updated as well. */
	replace grsswk`k' = grsswk_hat if (flag`j'==3 | flag`j'==5)
	replace hourpay`k' = hourpay_hat if (flag`j'==3 | flag`j'==5)

	gen lhe`k' = ln(hourpay`k')
	gen lhr`k' = ln(hrrate`k')
	egen lhe_1`k' = mean(lhe`k')
	gen lhsq2`k' = (lhe`k' - lhe_1`k')^2
		
	replace lhr`k'=. if lhr`k' < 0
		replace lhe`k'=. if lhe`k' < 0
		drop  hrrate_hat
		drop  grsswk_hat
		drop  hourpay_hat
	
	replace maxloop= `j'	
		local j = `j'+1
			}
			
save pre_imputation.dta, replace
clear
			
/* Clean up pre_imputation1.dta. */ 			
clear
use pre_imputation.dta	
local suf = maxloop[1]

/* The code chooses the maxloops version of the dynamically generated variables as the one retained in the final dataset, and deletes the versions generated by the earlier regressions.
The letter dropping is sufficient to succesfully implement "drop xxxx*" on the undesired xxxx variables. */
rename 	hrrate`suf' hrrat
drop hrrate*
rename hrrat hrrate

rename 	hourpay`suf' hourpa
drop hourpay*
rename hourpa hourpay

rename lhe_1`suf' lh_mean
rename lhe`suf' lh
drop lhe*
rename lh_mean lhe_1 
rename lh lhe

rename lhr`suf' lh
drop lhr*
rename lh lhr

rename lhsq2`suf' lhsq
drop lhsq2*
rename lhsq lhsq2

rename y_hat`suf' y_ha
drop y_hat*
rename y_ha y_hat

rename e_hat_student`suf' e_hat_studen
drop   e_hat_student*
rename e_hat_studen e_hat_student

rename flag`suf' fla
drop flag*
rename fla flag

rename grsswk`suf' grssw
drop grsswk*
rename grssw grsswk

rename cooks`suf' cook
drop cooks*
rename cook cooks

order hrrate grsswk hourpay lhe lhr lhe_1 lhsq2 cooks y_hat e_hat_student 
drop flag maxloop

/* The dataset is saved to be used in later stages and includes all the new data that has been treated, so the last loop version of data */
save pre_imputation.dta, replace
clear
		
/* Label the flag values for a report on the imputations that were made and in which step. A non-missing entry for flag`j' means that the imputation was made on round `j'. The maximum
value of j is the value in which there are no more outliers. Therefore, the final round of outlier processing takes happens on loop number j-1. */

/* Append all the imputed`i'.dta files together for a report on the outlier cleanup process. */
local g = `j'-1

/* This loop gives a common name for any loop-generated variables that you want to be in the same column under a commmon name in the outlier report. Keep in mind that the same columns
i.e. variables will in the outlier report refer to different versions of the dataset, because it is processed dynamically. The empirical distribution of the data changes as you move
down the rows of the outlier report. */
forvalues i =1/`g' {
use imputed`i'.dta
rename cooks`i' cooks
rename hrrate`i' hrrate
rename grsswk`i' grsswk
rename hrrate_p1_`i' hrrate_p1
rename hrrate_p99_`i' hrrate_p99
rename hourpay`i' hourpay
rename hourpay_p1_`i' hourpay_p1
rename hourpay_p99_`i' hourpay_p99
save imputed`i'.dta, replace
}
/* clear */

/* This loop appends all of the imputed`i'.dta files together to create the outlier report. */
use imputed1.dta
forvalues i =2/`g' {
append using imputed`i'.dta
}

/* Create value labels to annotate the outlier report. */
#delimit;
label define flaglab 
1 "cooks>0.02 & approx. 10-fold scaling error in hrrate" 
2 "cooks> 0.02 & approx. 100-fold scaling error in hrrate" 
3 "cooks>0.02 & netwk>grsswk" 
4 "cooks>0.02 & hrrate outside of 1-99 percentile range of non-outlier distr." 
5 "cooks>0.02 & hourpay outside of 1-99 percentile range of non-outlier distr." 
6 "cooks>0.02 & hrrate & hourpay outside of 1-99 percentile range of non-outlier distr."
7 "cooks > 0.02 and no obvious other problems"
8 "cooks=!. and hrrate outside of 1-99 percentile range of non-outlier distr.";
#delimit cr

forvalues i = 1/`g' {
label values flag`i' flaglab
}
.

/* Generate a single flag code variable for convenience. */
gen flag_code=.
forvalues i= 1/`g'{
replace flag_code= 1 if flag`i'==1
replace flag_code= 2 if flag`i'==2
replace flag_code= 3 if flag`i'==3
replace flag_code= 4 if flag`i'==4
replace flag_code= 5 if flag`i'==5
replace flag_code= 6 if flag`i'==6
replace flag_code= 7 if flag`i'==7
replace flag_code= 8 if flag`i'==8
}

/* Generate action_taken variable, just for the label. Every flagj has the same action, no matter the loop number on which the outlier was identified. */
gen action_taken=.
forvalues i= 1/`g' {
replace action_taken=1 if flag`i'==1
replace action_taken=2 if flag`i'==2
replace action_taken=3 if flag`i'==3
replace action_taken=4 if flag`i'==4
replace action_taken=5 if flag`i'==5
replace action_taken=6 if flag`i'==6
replace action_taken=7 if flag`i'==7
replace action_taken=8 if flag`i'==8
}

#delimit;
label define action_taken_lab 
1 "Replaced hrrate with hrrate/10" 
2 "Replaced hrrate with hrrate/100" 
3 "Recalculated hourpay as netwk/(bushr) or netwk/(bushr+pothr)" 
4 "Set hrrate =." 
5 "Set hourpay=."
6 "Set hrrate=. & hourpay=."
7 "set hrrate=."
8 "set hrrate=." ;
#delimit cr

label values action_taken action_taken_lab

/* Now  order the variables for the final outlier report. */
order sernum cooks flag* flag_code action_taken hrrate hrrate_hat hourpay hourpay_hat grsswk netwk grsswk_hat pothr bushr hrrate_p1 hrrate_p99

/* This is where you can see what observations have been treated and for what reason */
save "V:\Users\\${name}\\${location}\\${folder}\outlier_report_${time}.dta", replace

/* Finally get rid of the individual imputed.dta files as the information within these is now in the outlier report. */
forvalues i =1/`g' {
erase imputed`i'.dta
}

/* Editing the pre_imputation.dta file to make sure variable names are as required for the doner process. */
/* The code uses the fitted values from the final regression as a measure of neighborliness between values (the variable is called allimput). It takes all of the data in one of the
age brackets from the LFS dataset.  
Using a 2009Q4 data example: 
For example, the first youth age bracket, age<18 (around 200 observations) (observations numbers reported here are illustrative for the 2009Q4 dataset).
Then it splits this data into three.  
(A) The donor=1 set (over 100 observations).  These are observations with a value for hhrate and for which the regression standardized residual lies between the 1st and 99th percentile.
Generates 20 new variables. 
iok: k=0,1,…,9 and hik: k=0,1,…,9 which are the kth lag and kth lead (respectively) of hrrate.  
Where the iok and hik are missing, they themselves inherit values from their 1st lead or lag.  This is to fill in gaps which may occur if the kth lag or lead is missing.  But it won't
work if the 1st lead or lag is itself missing.
(B)  A subset of the donor=0 set which have a missing hrrate but which do not have a missing fitted value (around 50 observations).   
The (A) and (B) sets are appended together and sorted by fitted value.  The (B) set then receives nearest neighbor values for iok and hik.  
These values are copied into new variables called hineik[+1], and loneik[+1] k=1,...,9, and only variables up to k=5 are retained in the final dataset.
(C) A second subset of the donor=0 set (disjoint from B)) which have a missing fitted value OR which do not have missing hrrate. (less than 50 observations) These do not receive nearest neighbor
lag values (assumed to be ok values, which simply are outliers in terms of their fitted values). These get appended back in near the end of the code.
In fact, the (A), (B) and (C) observations for age<18 all get appended back together near the end of the code. This is then repeated for the 18-21 age group, and the age>21 age group respectively.

The new variables are then merged into the original (12,000) dataset. A new set of variables is then created nmwdonv: v=1,...,10. These indicate whether the values of the ten variables
loneik and hineik: k=1,...,5 are below the relevant minimum wage for the age group. (The variables are equal to 1 if so, and 0 if not). The variable nmwdonv: v=1,...,10 are then averaged
to create a new variable called nmwdon which will be between 1 and 10. */

/* ${time} differences: ${time} features different agebands etc, so the groupings become different */

clear all
set more off
cd "V:\Users\\${name}\\${location}\\${folder}"			

/* Preliminaries */
use "pre_imputation.dta", clear     						   /* this loads in the treated dataset. */
        rename e_hat_student sre_1
		egen p1= pctile(sre_1), p(1)                           /* Generate the 1st and 99th percentiles of the regression standardized residual. */
		egen p99= pctile(sre_1), p(99)
		rename y_hat allimput
		keep sernum age allimput hrrate sre_1 p1 p99           /* Drop all the variables not required. */
		gen donor=0
		replace donor=1 if (sre_1>p1 & sre_1<p99)              /* Donor cases lie between the 1st and 99th percentiles. */
		replace hrrate=. if hrrate<1                           /* If hrrate is less than 1, set it to missing. */
		save "${time}_fullset.dta", replace               
		preserve 
		
/* Split the dataset according to the required agebands (which correspond to different wages). */	
		keep if age < 18                                         
			save "${time}_under18.dta", replace
		restore                                                  
		preserve
		keep if age>17 & age<21
			save "${time}_18to20.dta", replace 
		restore
		preserve
		keep if age >20 & age<25
		    save "${time}_21to24.dta", replace
		restore 
		keep if age>=25
			save "${time}_25plus.dta", replace 

/* Nearest Neighbour Method for 17 and below (teens) */
				use "${time}_under18", clear              			
				preserve	
				keep if hrrate==. & allimput !=.                        /* Create a set of receivers, those with a missing hrrate and valid predicted value. This is a subset of donor ==0 cases */
							save "${time}_under18receivers", replace    
				restore								/* Restore full teenage set */
										keep if donor==1                 /* Select donor set only. */                

										sort allimput sernum
										forvalues j=0/9 {
											gen io`j' = hrrate[_n-`j']   /* io0,..,ioj,.,io9 are working variables equal to the jth lag of hrrate. */																   							
										}
										
										gsort -allimput -sernum 	     /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {												
											gen hi`j' = hrrate[_n-`j']	 /* hi0,...hij,...,hi9 are working variables equal to the jth lead of hrrate. */				   							
										}	
											
							append using ${time}_under18receivers   /* Append the processed donor cases to the  receiver set. */
							sort allimput sernum                         /* Sort on the regression predicted value.  This allows for donation in the following steps */
										
										forvalues j=0/9 {
											replace io`j' = io`j'[_n-1] if missing(io`j')   /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen lonei`k' = io`j'        if missing(hrrate)  /* The lonei1,...,loneik,...,lonei10 variables are the low imputed values defined only if hrrate is missing. */
										
										}

										gsort -allimput -sernum            					  /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {
											replace hi`j' = hi`j'[_n-1] if missing(hi`j')      /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen hinei`k' = hi`j'                               /* The hinei1,...,hineik,..., hinei10 variables are the low imputed values defined only if hrrate is missing. */
										}

										forvalues j=1/5  {                                     
											local k = 11 - `j'
											replace lonei`j' = hinei`k' if missing(lonei`j')
											replace hinei`j' = lonei`k' if missing(hinei`j')
										}

				drop io0 io1 io2 io3 io4 io5 io6 io7 io8 io9 hi0 hi1 hi2 hi3 hi4 hi5 hi6 hi7 hi8 hi9 lonei6 lonei7 lonei8 lonei9 lonei10 hinei6 hinei7 hinei8 hinei9 hinei10 /* Drop unneeded working variables.   */
				                                                                      /* lonei1,...,lonei5, hinei1,...,hinei5 are the final nearest neighbour imputed variables. lags and leads 6-10 not required  */
				save "${time}_under18allimput.dta", replace    

				use "${time}_under18.dta", clear   					 
				keep if allimput==. | (donor==0 & hrrate>0 & hrrate !=.)     /* Select the other donor=0 cases, which were not donors because their standardized residual value is outside the 1st and 99th percentiles */
				append using ${time}_under18allimput                    /* Add those cases to the dataset to the donors and receivers separated before.  You should now have all the observations from the teenage set. */
							
									     forvalues j=1/5 {                   /* Sets the lonei1,...,loneik,...,lonei5 and hinei1,...,hineik,...hinei5 variables equal to hrrate if hrrate is not missing.  */
											replace lonei`j' = hrrate if hrrate !=.  
											replace hinei`j' = hrrate if hrrate !=.	 														 
										 }
									
											sort sernum

save "${time}_under18hourlyrates", replace       /* Save the final version of the dataset*/
erase "${time}_under18allimput.dta"                     /* Remove the three working datasets from the teenage processing. */
erase "${time}_under18.dta"
erase "${time}_under18receivers.dta"

/* Nearest neighbour method for 18-20. */
	use "${time}_18to20.dta", clear              /* Select full young dataset.*/			
				preserve	
				keep if hrrate==. & allimput !=.                        /* Create a set of receivers, those with a missing hrrate and valid predicted value.   This is a subset of donor ==0 cases */
							save "${time}_18to20receivers", replace    /* Save the receiver set. */
				restore								/* Restore full young set */

										keep if donor==1                 /* Select donor set only. */                

										sort allimput sernum
										forvalues j=0/9 {
											gen io`j' = hrrate[_n-`j']   /* io0,..,ioj,.,io9 are working variables equal to the jth lag of hrrate.  */																   							
										}
										
										gsort -allimput -sernum 	     /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {												
											gen hi`j' = hrrate[_n-`j']	 /* hi0,...hij,...,hi9 are working variables equal to the jth lead of hrrate. */				   							
										}	
											
							append using ${time}_18to20receivers   /*  Append the processed donor cases to the  receiver set.  */
							sort allimput sernum                         /* Sort on the regression predicted value.  This allows for donation in the following steps */
										
										forvalues j=0/9 {
											replace io`j' = io`j'[_n-1] if missing(io`j')    /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen lonei`k' = io`j'        if missing(hrrate)  /* The lonei1,...,loneik,...,lonei10 variables are the low imputed values defined only if hrrate is missing.*/
										}

										gsort -allimput -sernum            					  /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {
											replace hi`j' = hi`j'[_n-1] if missing(hi`j')        /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will).*/
											local k = `j'+1
											gen hinei`k' = hi`j'                               /* The hinei1,...,hineik,..., hinei10 variables are the low imputed values defined only if hrrate is missing.*/
										}

													forvalues j=1/5  {                                      
											local k = 11 - `j'
											replace lonei`j' = hinei`k' if missing(lonei`j')
											replace hinei`j' = lonei`k' if missing(hinei`j')
																			
										
										}

				drop io0 io1 io2 io3 io4 io5 io6 io7 io8 io9 hi0 hi1 hi2 hi3 hi4 hi5 hi6 hi7 hi8 hi9 lonei6 lonei7 lonei8 lonei9 lonei10 hinei6 hinei7 hinei8 hinei9 hinei10 /* Drop unneeded working variables. */
				                                                                      /* lonei1,...,lonei5, hinei1,...,hinei5 are the final nearest neighbour imputed variables. lags and leads 6-10 not required  */
				save "${time}_18to20allimput.dta", replace    

				use "${time}_18to20.dta", clear   					 
				keep if allimput==. | (donor==0 & hrrate>0 & hrrate !=.)     /* Select the other donor=0 cases, which were not donors because their standardized residual value is outside the 1st and 99th percentiles */
				append using ${time}_18to20allimput                      /* Add those cases to the dataset to the donors and receivers separated before.  You should now have all the observations from the young set */
																			
									     forvalues j=1/5 {                   /* Sets the lonei1,...,loneik,...,lonei5 and hinei1,...,hineik,...hinei5 variables equal to hrrate if hrrate is not missing. */
											replace lonei`j' = hrrate if hrrate !=.  
											replace hinei`j' = hrrate if hrrate !=.	 														 
										 }
											sort sernum


save "${time}_18to20hourlyrates", replace       /* Save the final version of the dataset */
erase "${time}_18to20allimput.dta"                     /* Remove the three working datasets from the young processing.  */
erase "${time}_18to20.dta"
erase "${time}_18to20receivers.dta"

/* Nearest neighbour method for 21to24 */ 
	use "${time}_21to24.dta", clear              /* Select full mature dataset. */			
				preserve	
				keep if hrrate==. & allimput !=.                        /* Create a set of receivers, those with a missing hrrate and valid predicted value. This is a subset of donor ==0 cases */
							save "${time}_21to24receivers", replace    /* Save the receiver set. */
							
				restore								/* Restore full mature set */


										keep if donor==1                 /* Select donor set only. */                

										sort allimput sernum
										forvalues j=0/9 {
											gen io`j' = hrrate[_n-`j']   /* io0,..,ioj,.,io9 are working variables equal to the jth lag of hrrate.  */																   							
										}
										
										gsort -allimput -sernum 	     /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {												
											gen hi`j' = hrrate[_n-`j']	 /* hi0,...hij,...,hi9 are working variables equal to the jth lead of hrrate. */				   							
										}	
											
							append using ${time}_21to24receivers   /* Append the processed donor cases to the  receiver set.  */
							sort allimput sernum                         /* Sort on the regression predicted value.  This allows for donation in the following steps */
										
										forvalues j=0/9 {
											replace io`j' = io`j'[_n-1] if missing(io`j')    /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen lonei`k' = io`j'        if missing(hrrate)   /* The lonei1,...,loneik,...,lonei10 variables are the low imputed values defined only if hrrate is missing. */
										}

										gsort -allimput -sernum            				     /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {
											replace hi`j' = hi`j'[_n-1] if missing(hi`j')    /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen hinei`k' = hi`j'                             /* The hinei1,...,hineik,..., hinei10 variables are the low imputed values defined only if hrrate is missing. */
										}

										forvalues j=1/5  {                                     
											local k = 11 - `j'
											replace lonei`j' = hinei`k' if missing(lonei`j')
											replace hinei`j' = lonei`k' if missing(hinei`j')
										}
										
				drop io0 io1 io2 io3 io4 io5 io6 io7 io8 io9 hi0 hi1 hi2 hi3 hi4 hi5 hi6 hi7 hi8 hi9 lonei6 lonei7 lonei8 lonei9 lonei10 hinei6 hinei7 hinei8 hinei9 hinei10 /* Drop unneeded working variables.   */
				                                                                      /* lonei1,...,lonei5, hinei1,...,hinei5 are the final nearest neighbour imputed variables. lags and leads 6-10 not required  */
				save "${time}_21to24allimput.dta", replace    

				use "${time}_21to24.dta", clear   					 
				keep if allimput==. | (donor==0 & hrrate>0 & hrrate !=.)     /* Select the other donor=0 cases, which were not donors because their standardized residual value is outside the 1st and 99th percentiles */
				append using ${time}_21to24allimput                    /* Add those cases to the dataset to the donors and receivers separated before.  You should now have all the observations from the mature set. */
									
									     forvalues j=1/5 {                   /* Sets the lonei1,...,loneik,...,lonei5 and hinei1,...,hineik,...hinei5 variables equal to hrrate if hrrate is not missing.  */
											replace lonei`j' = hrrate if hrrate !=.  
											replace hinei`j' = hrrate if hrrate !=.	 														 
										 }
											sort sernum

save "${time}_21to24hourlyrates", replace       /* Save the final version of the dataset */

erase "${time}_21to24allimput.dta"                     /* Remove the three working datasets from the mature processing. */
erase "${time}_21to24.dta"
erase "${time}_21to24receivers.dta"

/* Nearest neighbour method for 25+ (National Living wage) */
	use "${time}_25plus.dta", clear              /* Select full dataset.*/			
				preserve	
				keep if hrrate==. & allimput !=.                        /* Create a set of receivers, those with a missing hrrate and valid predicted value. This is a subset of donor ==0 cases */
							save "${time}_25plusreceivers", replace    /* Save the receiver set. */
				restore								/* Restore full set */
										keep if donor==1                 /* Select donor set only. */                
										sort allimput sernum
										forvalues j=0/9 {
											gen io`j' = hrrate[_n-`j']   /* io0,..,ioj,.,io9 are working variables equal to the jth lag of hrrate. */																   							
										}
										gsort -allimput -sernum 	     /* Invert the sort to get generate lead values using lag operation. */
										forvalues j=0/9 {												
											gen hi`j' = hrrate[_n-`j']	 /* hi0,...hij,...,hi9 are working variables equal to the jth lead of hrrate. */				   							
										}				
							append using ${time}_25plusreceivers   /* Append the processed donor cases to the  receiver set. */
							sort allimput sernum                         /* Sort on the regression predicted value.  This allows for donation in the following steps */
		
										forvalues j=0/9 {
											replace io`j' = io`j'[_n-1] if missing(io`j')   /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen lonei`k' = io`j'        if missing(hrrate)  /* The lonei1,...,loneik,...,lonei10 variables are the low imputed values defined only if hrrate is missing. */
										}
										gsort -allimput -sernum            					/* Invert the sort to get generate lead values using lag operation. */
										forvalues j=0/9 {
											replace hi`j' = hi`j'[_n-1] if missing(hi`j')   /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen hinei`k' = hi`j'                            /* The hinei1,...,hineik,..., hinei10 variables are the low imputed values defined only if hrrate is missing. */
										}
										forvalues j=1/5  {                                     
											local k = 11 - `j'
											replace lonei`j' = hinei`k' if missing(lonei`j')
											replace hinei`j' = lonei`k' if missing(hinei`j')
										}
				drop io0 io1 io2 io3 io4 io5 io6 io7 io8 io9 hi0 hi1 hi2 hi3 hi4 hi5 hi6 hi7 hi8 hi9 lonei6 lonei7 lonei8 lonei9 lonei10 hinei6 hinei7 hinei8 hinei9 hinei10 /* Drop unneeded working variables. */
				                                                                      /* lonei1,...,lonei5, hinei1,...,hinei5 are the final nearest neighbour imputed variables. lags and leads 6-10 not required  */
				save "${time}_25plusallimput.dta", replace    
				use "${time}_25plus.dta", clear   					 
				keep if allimput==. | (donor==0 & hrrate>0 & hrrate !=.)     /* Select the other donor=0 cases, which were not donors because their standardized residual value is outside the 1st and 99th percentiles */
				append using ${time}_25plusallimput                    /* Add those cases to the dataset to the donors and receivers separated before. You should now have all the observations from the mature set. */
									     forvalues j=1/5 {                   /* Sets the lonei1,...,loneik,...,lonei5 and hinei1,...,hineik,...hinei5 variables equal to hrrate if hrrate is not missing.  */
											replace lonei`j' = hrrate if hrrate !=.  
											replace hinei`j' = hrrate if hrrate !=.	 														 
										 }
											sort sernum
save "${time}_25plushourlyrates", replace       /* Save the final version of the dataset */
erase "${time}_25plusallimput.dta"                     /* Remove the three working datasets from the mature processing. */
erase "${time}_25plus.dta"
erase "${time}_25plusreceivers.dta"


/* Create Database for tables */
clear
use "${time}_25plushourlyrates.dta"
append using "${time}_21to24hourlyrates.dta"     /* Combine the four files and make a postdonor file, containing variables that have been treated */
append using "${time}_18to20hourlyrates.dta"
append using "${time}_under18hourlyrates.dta"
sort sernum 
save "${time}_postdonor.dta", replace              /* Combined version of the imputed data. */
erase "${time}_25plushourlyrates.dta"
erase "${time}_21to24hourlyrates.dta"     
erase "${time}_18to20hourlyrates.dta"
erase "${time}_under18hourlyrates.dta"
erase "${time}_fullset.dta"

/* Load in file prepared for imputation */
/* merge using the dataset previously created, dropping variables that will be held in both files to avoid duplication */
use "pre_imputation.dta", clear 
rename hrrate d0
merge using "${time}_postdonor"
drop allimput sre_1 d0 p1 p99 _merge

/* These will need changing on a half yearly basis, these are correct for october $(time) */
gen nmwu18= 4.00
gen nmw18to20= 5.55
gen nmw21to24= 6.95
gen nlw= 7.20

/* These have changed since 2009, so different agebands need to correspond to different nmw */
forvalues j=1/5 {                     
	local k = 6 - `j'
	gen nmwdon`j' = 1 if ((age <18 & lonei`k' !=. & lonei`k'<nmwu18) | (age> 17 & age< 21 & lonei`k' !=. & lonei`k'<nmw18to20) | (age> 20 & age< 25 & lonei`k' !=. & lonei`k'<nmw21to24) | (age>=25 & lonei`k' !=. & lonei`k'<nlw))
	replace nmwdon`j'=0 if ((age <18 & lonei`k' !=. & lonei`k' >=nmwu18) | (age>17 & age<21 & lonei`k' !=. & lonei`k'>=nmw18to20) | (age> 20 & age<25 & lonei`k' !=. & lonei`k'>=nmw21to24) | (age>=25 & lonei`k' !=. & lonei`k'>=nlw)) | apprcurr==1
}

forvalues j = 6/10 {	
	local k = `j' - 5
gen nmwdon`j' = 1 if ((age <18 & hinei`k' !=. & hinei`k'<nmwu18) | (age> 17 & age< 21 & hinei`k' !=. & hinei`k'<nmw18to20) | (age> 20 & age< 25 & hinei`k' !=. & hinei`k'<nmw21to24) | (age>=25 & hinei`k' !=. & hinei`k'<nlw))
	replace nmwdon`j'=0 if ((age <18 & hinei`k' !=. & hinei`k' >=nmwu18) | (age>17 & age<21 & hinei`k' !=. & hinei`k'>=nmw18to20) | (age> 20 & age<25 & hinei`k' !=. & hinei`k'>=nmw21to24) | (age>=25 & hinei`k' !=. & hinei`k'>=nlw)) | apprcurr==1
}

/* Weights need changing when we use certain data */
egen nmwdon= rowmean( nmwdon1 nmwdon2 nmwdon3 nmwdon4 nmwdon5 nmwdon6 nmwdon7 nmwdon8 nmwdon9 nmwdon10)
sum nmwdon
sum nmwdon [fweight=round(piwt17)]

/* so this dataset includes all the LFS variables and then the 10 new variables for pay alongside the other variables we have created in the previous versions too
Can average out the 10 variables to created an imputed_hrrate as it were */
save "V:\Users\\${name}\\${location}\\${folder}\_${time}_readyfortables", replace

/* Delete the old datasets that are unnecessary */
erase "${time}_postdonor.dta" 
erase "pre_imputation.dta"
erase "prep16.dta"
}


if "`1'" == "2" { 
*** Main Jobs- Create jobs databse ***
/* Setting up the LFS dataset: 
FOR ${time}, we updated piwt14 to piwt16 and to piwt17 
** discurr- discurr13 **
** levqual - levqul15 **
** hiqual- hiqual15 **
** sc2kmmj- sc10mmj **
This is where we load our LFS data in from, ${time}10 ${time}10 q corresponds to the start date and the end of the date in Quarters.
Previous analysis focussed on ${time} Q4 here, so that is the end and start date. 
Other listed variables are those used in the analysis. */

clear all
set more off
cd "V:\Programs\"
lfs ${lfstime} ${lfstime} q piwt17 pwt17 age sex marsta hiqual15 govtor levqul15 discurr13 ethukeul grsswk2 acthr2 hrrate2 mpnsr02 inds07s sc10smj secga scntga jobtyp2 secjmbr netwk2 cryox7 natox7 fled10 flexw7
save "V:\Users\\${name}\\${location}\\${folder}\low_pay16_sec.dta", replace

/* second jobs, uses population weights rather than income weights */
/* selects cases that have a grossing factor and filters out those that do not */
keep if secjmbr==1 & pwt17 > 0

/* Converting negative values to missing values */
mvdecode _all, mv(-8 -9)

/* create hourpay2 variable */
gen hourpay2= round(100*(grsswk2/acthr2))/100 if acthr2 > 0 & acthr2 !=. 

/* Creating new variables */
gen cryox7a=.
replace cryox7a=1 if cryox7==926
replace cryox7a=2 if cryox7!=926 & cryox7!=.
label define ukelse 1 "UK born" 2 "Non-UK born"
label values cryox7a ukelse
tab cryox7a

gen natox7a=.
replace natox7a=1 if natox7==926
replace natox7a=2 if natox7!=926 & natox7!=.
label values natox7a ukelse
tab natox7a

gen eth01a=. 
replace eth01a=1 if ethukeul==1
replace eth01a=2 if ethukeul!=1 & ethukeul!=. 
label define whitenonwhite 1 "White" 2 "Non-White" 
label values eth01a whitenonwhite 
tab eth01a

gen discurr13a=.
replace discurr13a=1 if discurr13==1| discurr13==2| discurr13==3
replace discurr13a=2 if discurr13==4
label define disab 1 "Disability" 2 "No Disability"
label values discurr13a disab
tab discurr13a

gen levqul15a=.
replace levqul15a=1 if levqul15==1| levqul15==2| levqul15==3| levqul15==4| levqul15==5| levqul15==6
replace levqul15a=2 if levqul15==7
label define qual 1 "Have Qualification" 2 "No qualification"
label values levqul15a qual
tab levqul15a

/* Set hrrate=996-999 as missing value as not recognised as such by the system */
mvdecode hrrate2, mv(996 997 998 999) 

/* Compute variables required in the regression analysis and tidy up ftptwk, sex and jobtyp so that are all 0 or 1 */
gen lhe2 = ln(hourpay2)
gen lwe2 = ln(grsswk2) 
gen lhr2 = ln(hrrate2)
gen agesq = age*age
gen female = sex-1
gen imperm2 = jobtyp2 - 1

/* Encode minimum and living wage agebands into binary variables, ready for regression
for ${time}, due to different agebands due to NLW, we need to change the age groups */ 
gen age1 =0
replace age1=1 if age < 18

gen age2 =0
replace age2=1 if age >= 18 & age <= 20

gen age3 =0
replace age3=1 if age >= 21 & age <=24

gen age4 =0 
replace age4=1 if age >=25

gen sernum = _n
gen const_ =1

/* If ln of hrrate is <0 (i.e. hrrate <£1/hr) set it to missing because it is implausible */
replace lhr2=. if lhr2 < 0

/* Create quadratic term. */
egen lhe2_1 = mean(lhe2)
gen lhsq22 = (lhe2 - lhe2_1)^2

/* Recode categorical variables to be used in the regression into binary, in preparation for the regression to be carried out, starting with miscellaneous variables, then variables relating to educational qualifications, regions, occupation and industry */
gen married=.
replace married=1 if marsta==2 | marsta ==6
replace married=0 if marsta==1| marsta==3| marsta==4| marsta==5 | marsta ==7 | marsta ==8 | marsta == 9

gen size2=.
replace size2=1 if mpnsr02==5| mpnsr02==6| mpnsr02==7| mpnsr02==8| mpnsr02==9
replace size2=0 if mpnsr02==1| mpnsr02==2| mpnsr02==3| mpnsr02==4  
  
gen ltwk2=.
replace ltwk2=0 if secga==1| secga==2| secga==3| secga==4| secga==5| secga==6| secga==7| secga==8| secga==9| secga==10| secga==11| secga==12| secga==13| secga==14| secga==15| secga==16|  secga==17| secga==18| secga==19| secga==20| secga==21| secga==22| secga==23| secga==24| secga==25| secga==26| secga==27| secga==28| secga==29| secga==30| secga==31| secga==32| secga==33|  secga==34| secga==35| secga==36| secga==37| secga==38| secga==39| secga==40| secga==41| secga==42| secga==43| secga==44| secga==45| secga==46| secga==47| secga==48| secga==49| secga==50| secga==51| secga==52| secga==95| secga==96| secga==97| secga==.
replace ltwk2=1 if secga==90

/* Recode qualifications variables */
recode hiqual15 (1/9 = 1) (10/85 =0), gen(q1)
recode hiqual15 (10/26=1)  (1/9=0)  (27/85=0), gen(q2)
recode hiqual15 (27/45=1)  (1/26=0)  (46/85=0), gen(q3)
recode hiqual15 (46/58=1)  (1/45=0)  (59/85=0), gen(q4)
recode hiqual15 (59/83=1)  (1/58=0)  (84/85=0), gen(q5)
recode hiqual15 (84/85=1)  (1/83=0), gen(q6)

/* Recode region variables */
recode govtor (1/2=1)  (3/20=0), gen(reg1)
recode govtor (3/5=1)  (1/2=0)  (6/20=0), gen(reg2)
recode govtor (6/8=1)  (1/5=0)  (9/20=0), gen(reg3)
recode govtor (9=1)  (1/8=0)  (10/20=0), gen(reg4)
recode govtor (10/11=1)  (1/9=0)  (12/20=0), gen(reg5)
recode govtor (12=1)  (1/11=0)  (13/20=0), gen(reg6)
recode govtor (13/14=1)  (1/12=0)  (15/20=0), gen(reg7)
recode govtor (15=1)  (1/14=0)  (16/20=0), gen(reg8)
recode govtor (16=1)  (1/15=0)  (17/20=0), gen(reg9)
recode  govtor (17=1)  (1/16=0)  (18/20=0), gen(reg10)
recode govtor (18/19=1)  (1/17=0)  (20=0), gen(reg11)
recode  govtor (20=1)  (1/19=0), gen(reg12)

/* Recode occupation variables */
recode  sc10smj (1=1)  (2/9=0), gen(soc12)
recode  sc10smj (2=1)  (1=0)  (3/9=0), gen(soc22)
recode sc10smj (3=1)  (1/2=0)  (4/9=0), gen(soc32)
recode sc10smj (4=1)  (1/3=0)  (5/9=0), gen(soc42)
recode sc10smj  (5=1)  (1/4=0)  (6/9=0), gen(soc52)
recode sc10smj  (6=1)  (1/5=0)  (7/9=0), gen(soc62)
recode sc10smj (7=1)  (1/6=0)  (8/9=0), gen(soc72)
recode  sc10smj (8=1)  (1/7=0)  (9=0), gen(soc82)
recode sc10smj (9=1)  (1/8=0), gen(soc92)

/* Recode industry variables */
gen inde07m2= .
replace inde07m2 =1 if inds07s==1 | inds07s== 2
replace inde07m2 =2 if inds07s==3 | inds07s==5
replace inde07m2 =3 if inds07s==4 
replace inde07m2 =4 if inds07s==6 
replace inde07m2 =5 if inds07s==7 | inds07s==8
replace inde07m2 =6 if inds07s==9 
replace inde07m2 =7 if inds07s==10 | inds07s==11 
replace inde07m2 =8 if inds07s==12 | inds07s==13 | inds07s==14 
replace inde07m2 =9 if inds07s==15 | inds07s==16 | inds07s==17 
replace inde07m2 =10 if inds07s==19  

recode inde07m2 (1=1) (2/9=0) (10=.), gen(ind12) 
recode inde07m2 (2=1) (1=0) (3/9=0) (10=.), gen(ind22)
recode inde07m2 (3=1) (1/2=0) (4/9=0) (10=.), gen(ind32)
recode inde07m2 (4=1) (1/3=0) (5/9=0) (10=.), gen(ind42)
recode inde07m2 (5=1) (1/4=0) (6/9=0) (10=.), gen(ind52)
recode inde07m2 (6=1) (1/5=0) (7/9=0) (10=.), gen(ind62)
recode inde07m2 (7=1) (1/6=0) (8/9=0) (10=.), gen(ind72) 
recode inde07m2 (8=1) (1/7=0) (9=0) (10=.), gen(ind82)
recode inde07m2 (9=1) (1/8=0) (10=.), gen(ind92)

/* Assign a value of 0 to a new variable 'period' for cases in which pay period is less than weekly and a value of 1 to other cases. */
gen period = 0  if (secga == 2 | secga == 3 | secga == 4 | secga == 5 | secga == 7 | secga == 8 | secga == 9| secga == 10 | secga == 13 |secga ==26 | secga == 52 |secga == 95 | secga == 97  | scntga == 2 | scntga == 3 | scntga == 4 | scntga == 5 | scntga == 7 | scntga == 8 | scntga == 9| scntga == 10 | scntga == 13 | scntga ==26 | scntga == 52 |scntga == 95 | scntga == 97) 
replace period = 1  if (secga == 1 | secga == 90 | scntga == 1 | scntga == 90 ) 

/* Create ageband variable 
agebands need to be updated for ${time} as changes */
gen ageband=.
replace ageband=0 if age < 18
replace ageband=1 if age >= 18 & age <=20
replace ageband=2 if age >= 21 & age < 25
replace ageband=3 if age >=25
label define bands 0 "<18" 1 "18-20" 2 "21-24" 3 "25+"
label values ageband bands
tab ageband

save "V:\Users\\${name}\\${location}\\${folder}\prep16_sec.dta", replace

/* The same methodoloy/processing for Main jobs */
clear all
set more off 
cd "V:\Users\\${name}\\${location}\\${folder}"
graph drop _all

use "V:\Users\\${name}\\${location}\\${folder}\prep16_sec.dta", clear

capture: graph drop _all
local j = 1
local i = _N

rename lhr2 lhr_sec1
rename lhe2 lhe_sec1
rename lhsq22 lhsq2_sec1

rename hrrate2 hrrate_sec1
rename hourpay2 hourpay_sec1
rename grsswk2 grsswk_sec1

gen maxloop=.

while (`i'>0) {	
	display "i="`i'
	display "j="`j'
	regress lhr_sec`j' lhe_sec`j' lhsq2_sec`j' age agesq female ind12 ind22 ind32 ind42 ind52 ind62 ind72 ind92 ltwk2 married q1 q2 q4 q5 q6 period reg1 reg10 reg11 reg12 reg2 reg3 reg4  reg5 reg6 reg7 reg9 size2 soc12 soc22 soc32 soc52 soc62 soc72 soc82 soc92 age1 age2 imperm2
	predict cooks`j', cooksd
	
	/* Standardized predicted value. */
	predict y_hat`j'
	egen y_hat_bar=mean(y_hat`j')
	egen sd_y_hat = sd(y_hat`j')
	gen stan_y_hat=(y_hat`j' - y_hat_bar)/sd_y_hat
	label variable stan_y_hat "Standardized predicted value"
	
	/* Studentized residuals. */
	predict e_hat_student`j', rstudent
	
	/* PP-normal plots of studentized residuals of lhr. */
	local gn=`j'-1
	pnorm e_hat_student`j', name(ga`j-1')
	
	/* Scatter plot of studentized residuals against standardized predicted value */
	/* graph twoway (scatter e_hat_student`j' stan_y_hat if cooks`j'<=0.04) (scatter e_hat_student stan_y_hat if cooks`j'>0.04), ysc(r(0, 20)) xsc(r(-7.5, 7.5)) name(gb`j-1') */
	graph twoway (scatter e_hat_student`j' stan_y_hat if cooks`j'<=0.04) (scatter e_hat_student`j' stan_y_hat if cooks`j'>0.04, mcolor(red)), legend(label(1 "Cook's dist.<=0.04") label(2 "Cook's dist>0.04")) name(gb`j-1')
	
	/* Drop the graphing variables on each loop iteration. */
	drop y_hat_bar sd_y_hat stan_y_hat
	
	egen hrrate_sec_p1_a`j' = pctile(hrrate_sec`j') if cooks`j'<=0.04, p(1) 
	egen hrrate_sec_p99_a`j'= pctile(hrrate_sec`j') if cooks`j'<=0.04 , p(99) 
	egen hourpay_sec_p1_a`j' = pctile(hourpay_sec`j') if cooks`j' <=0.04, p(1) 
	egen hourpay_sec_p99_a`j'= pctile(hourpay_sec`j') if cooks`j' <= 0.04 , p(99) 
	
	egen hrrate_sec_p1_`j'=mean(hrrate_sec_p1_a`j')
	egen hrrate_sec_p99_`j'=mean(hrrate_sec_p99_a`j')
	egen hourpay_sec_p1_`j'=mean(hourpay_sec_p1_a`j')
	egen hourpay_sec_p99_`j'=mean(hourpay_sec_p99_a`j')
	
	drop hrrate_sec_p1_a`j' hrrate_sec_p99_a`j' hourpay_sec_p1_a`j' hourpay_sec_p99_a`j'
	
	gen flag`j'=.
	gen hrrate_sec_hat=.
	gen grsswk_sec_hat=.
	gen hourpay_sec_hat=.
	
	gen hourpay_sec_10_lower = 9*hourpay_sec`j'
	gen hourpay_sec_10_upper = 11*hourpay_sec`j'
	gen hourpay_sec_100_lower = 90 * hourpay_sec`j'
	gen hourpay_sec_100_upper = 110 * hourpay_sec`j'
	
	gen vbldista = (hrrate_sec`j' - hourpay_sec`j') / hourpay_sec`j'
	gen vbldistb = (hourpay_sec`j' - hrrate_sec`j') / (hrrate_sec`j')
	gen vbldist`j' = 0
	replace vbldist`j' = 1 if (vbldista>0.3 | vbldistb>0.3)
	
	drop vbldista
	drop vbldistb
	
	/* Flagj = 1:  Approx 10-fold scaling errors in hrrate_sec. */
	replace hrrate_sec_hat=hrrate_sec`j'/10	  if ((cooks`j'>0.04) & (cooks`j' !=.)& (vbldist`j'==1) &(hrrate_sec`j'>hourpay_sec_10_lower) & (hrrate_sec`j'<hourpay_sec_10_upper))
	replace flag`j'=1 if ((cooks`j'>0.04) & (cooks`j' !=.)& (vbldist`j'==1)&(hrrate_sec`j'>hourpay_sec_10_lower) & (hrrate_sec`j'<hourpay_sec_10_upper))
	
	/* Flagj = 2:  Approx 100-fold scaling errors in hrrate_sec. */
	replace hrrate_sec_hat=hrrate_sec`j'/100 if ((cooks`j'>0.04)& (cooks`j' !=.)& (vbldist`j'==1)&(hrrate_sec`j'>hourpay_sec_100_lower) & (hrrate_sec`j'<hourpay_sec_100_upper)) 
	replace flag`j'=2 if ((cooks`j'>0.04) & (cooks`j' !=.)& (vbldist`j'==1) &(hrrate_sec`j'>hourpay_sec_100_lower) & (hrrate_sec`j'<hourpay_sec_100_upper))

	drop hourpay_sec_10_lower hourpay_sec_10_upper hourpay_sec_100_lower hourpay_sec_100_upper
	
	/* Flagj = 3: Netwk2>grsswk_sec => use netwk2 instead. */
	replace grsswk_sec_hat=netwk2 if ((cooks`j'>0.04)&(cooks`j' !=.)&(grsswk_sec`j'<netwk2)& (vbldist`j'==1))
	replace flag`j'=3 if ((cooks`j'>0.04) & (cooks`j' !=.) & (grsswk_sec`j'<netwk2)& (vbldist`j'==1))
	replace hourpay_sec_hat = grsswk_sec_hat/(acthr2) if ((flag`j'==3) & (acthr2 >= 0 & acthr2 <= 97)& (vbldist`j'==1))
	
	/* Flagj = 4: Outliers with hrrate_sec outside, hourpay_sec inside of 1-99 percentile range (and none of the previous flags apply). */
	replace hrrate_sec_hat= . if ((cooks`j'>0.04)& (cooks`j' !=.) & (vbldist`j'==1) & (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3) & (hrrate_sec`j'<hrrate_sec_p1_`j' | hrrate_sec`j'>hrrate_sec_p99_`j')  & (hourpay_sec`j'>hourpay_sec_p1_`j' & hourpay_sec`j'<hourpay_sec_p99_`j'))
	replace flag`j'=4 if ((cooks`j'>0.04)& (cooks`j' !=.) & (vbldist`j'==1) & (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3) &(hrrate_sec`j'<hrrate_sec_p1_`j' | hrrate_sec`j'>hrrate_sec_p99_`j') & (hourpay_sec`j'>hourpay_sec_p1_`j' & hourpay_sec`j'<hourpay_sec_p99_`j'))
	
	/* Flagj = 5: Outliers with hourpay_sec outside, hrrate_sec inside of 1-99 percentile range (and none of the previous flags apply). */
	replace hourpay_sec_hat = . if ((cooks`j'>0.04)& (cooks`j' !=.)& (vbldist`j'==1) & (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3)& (flag`j'!=4) & (hourpay_sec`j'<hourpay_sec_p1_`j' | hourpay_sec`j'>hourpay_sec_p99_`j') & (hrrate_sec`j'>hrrate_sec_p1_`j' & hrrate_sec`j'<hrrate_sec_p99_`j')  )
	replace flag`j'=5 if ((cooks`j'>0.04)& (cooks`j' !=.)& (vbldist`j'==1) & (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3)& (flag`j'!=4) &(hourpay_sec`j'<hourpay_sec_p1_`j' |  hourpay_sec`j'>hourpay_sec_p99_`j') & (hrrate_sec`j'>hrrate_sec_p1_`j' & hrrate_sec`j'<hrrate_sec_p99_`j')  )
	
	/* Flagj = 6:  Outliers with hrrate_sec outside of 1-99 percentile range AND hourpay_sec outside of 1-99 percentile range (and none of previous flags apply). */
	replace flag`j'=6 if ((cooks`j'>0.04) & (cooks`j' !=.)& (vbldist`j'==1) & (hourpay_sec`j'<hourpay_sec_p1_`j' | hourpay_sec`j'>hourpay_sec_p99_`j') & (hrrate_sec`j'<hrrate_sec_p1_`j'  | hrrate_sec`j'>hrrate_sec_p99_`j') & (flag`j'!=1 ) & (flag`j'!=2) & (flag`j'!=3) & (flag`j'!=4) & (flag`j'!=5))
	replace hrrate_sec_hat = . if flag`j'==6
	replace hourpay_sec_hat = . if flag`j'==6
	
    /* Flagj = 7: Outliers have cooks > 0.02 and no obvious other problems */
	replace flag`j'=7 if ((cooks`j'>0.04) & (cooks`j' !=.) & (vbldist`j'==1) & (flag`j' !=1) &(flag`j' !=2) & (flag`j' !=3) & (flag`j' !=4) & (flag`j' !=5)  & (flag`j' !=6))
	gen hrrate_storage_sec`j'= hrrate_sec`j'
	replace hrrate_sec_hat = . if flag`j'==7
	
    /* Flagj = 8: Outliers have cooks missing and hrrate lies outside the hrrate is outside the 1-99 percentile range. */
	replace flag`j'=8 if ((cooks`j'==.) & (flag`j' !=1) &(flag`j' !=2) & (flag`j' !=3) & (flag`j' !=4) & (flag`j' !=5)  & (flag`j' !=6) & (flag`j'!=7) & (hrrate_sec`j'<hrrate_sec_p1_`j' | hrrate_sec`j'>hrrate_sec_p99_`j'))
	/* gen hrrate_storage`j'= hrrate`j'*/
	replace hrrate_sec_hat = . if flag`j'==8
	
    preserve
	keep if (cooks`j'>0.04 ) & (cooks`j' !=.) & (vbldist`j'==1)
	keep sernum hrrate_sec`j' hourpay_sec`j' hrrate_sec_hat hrrate_storage_sec`j' hourpay_sec_hat grsswk_sec`j' netwk2 acthr2 grsswk_sec_hat flag*  cooks`j' vbldist`j'  hrrate_sec_p1_`j' hrrate_sec_p99_`j' hourpay_sec_p1_`j' hourpay_sec_p99_`j'
	local i = _N 	
	save "imputed_sec`j'.dta", replace
	restore	
			
	/* Put the new fitted values into the variables for the regression in the next step. */
	local k=`j'+1
		
	gen hrrate_sec`k'=hrrate_sec`j'
	gen grsswk_sec`k'=grsswk_sec`j'
	gen hourpay_sec`k'=hourpay_sec`j'
	
	/* Flags 1,2,4,6,7 & 8 indicate that hrrate_s should be updated in the next iteration. */
	replace hrrate_sec`k' = hrrate_sec_hat if (flag`j'==1 | flag`j'==2 | flag`j'==4| flag`j'==6| flag`j'==7| flag`j'==8)
	
	/* Flags 3 and 5 indicates that hourpay_s should be updated in the next iteration, and grsswk_s gets updated as well. */
	replace grsswk_sec`k' = grsswk_sec_hat if (flag`j'==3 | flag`j'==5)
	replace hourpay_sec`k' = hourpay_sec_hat if (flag`j'==3 | flag`j'==5)

	gen lhe_sec`k' = ln(hourpay_sec`k')
	gen lhr_sec`k' = ln(hrrate_sec`k')
	egen lhe_sec_1`k' = mean(lhe_sec`k')
	gen lhsq2_sec`k' = (lhe_sec`k' - lhe_sec_1`k')^2
		
	replace lhr_sec`k'=. if lhr_sec`k' < 0
		replace lhe_sec`k'=. if lhe_sec`k' < 0
				
		drop  hrrate_sec_hat
		drop  grsswk_sec_hat
		drop  hourpay_sec_hat
		
	replace maxloop= `j'	
		local j = `j'+1
			}

save "pre_imputation_sec.dta", replace
clear

/* Clean up pre_imputation1.dta. */			
clear
use pre_imputation_sec.dta	

local suf = maxloop[1]

/* The following code chooses the maxloops version of the dynamically generated variables as the one retained in the final dataset, and deletes the versions generated by the earlier 
regressions. The letter dropping is sufficient to succesfully implement "drop xxxx*" on the undesired xxxx variables. */
rename 	hrrate_sec`suf' hrrat
drop hrrate_sec*
rename hrrat hrrate_sec

rename 	hourpay_sec`suf' hourpa
drop hourpay_sec*
rename hourpa hourpay_sec

rename lhe_sec_1`suf' lh_sec_mean
rename lhe_sec`suf' lh_sec
drop lhe_sec*
rename lh_sec_mean lhe_sec_1 
rename lh_sec lhe_sec

rename lhr_sec`suf' lh_sec
drop lhr_sec*
rename lh_sec lhr_sec

rename lhsq2_sec`suf' lhsq_sec
drop lhsq2_sec*
rename lhsq_sec lhsq2_sec

rename y_hat`suf' y_ha
drop y_hat*
rename y_ha y_hat

rename e_hat_student`suf' e_hat_studen
drop   e_hat_student*
rename e_hat_studen e_hat_student

rename flag`suf' fla
drop flag*
rename fla flag

rename grsswk_sec`suf' grssw
drop grsswk_sec*
rename grssw grsswk_sec

rename cooks`suf' cook
drop cooks*
rename cook cooks

order hrrate_sec grsswk_sec hourpay_sec lhe_sec lhr_sec lhe_sec_1 lhsq2_sec cooks y_hat e_hat_student 
local g = `j'-1

forvalues i=1/`g' {
drop vbldist`i' hrrate_storage_sec`i'
} 

drop flag maxloop
save pre_imputation_sec.dta, replace
clear
		
/* Label the flag values for a report on the imputations that were made and in which step. A non-missing entry for flag`j' means that the imputation was made on round `j'. The maximum 
value of j is the value in which there are no more outliers. Therefore, the final round of outlier processing takes happens on loop number j-1.
Append all the imputed`i'.dta files together for a report on the outlier cleanup process. */
local g = `j'-1

/* This loop gives a common name for any loop-generated variables that you want to be in the same column under a commmon name in the outlier report. Keep in mind that the same columns 
i.e. variables will in the outlier report refer to different versions of the dataset, because it is processed dynamically. The empirical distribution of the data changes as you move 
down the rows of the outlier report. */

forvalues i =1/`g' {
use imputed_sec`i'.dta
rename cooks`i' cooks
rename hrrate_sec`i' hrrate_sec
rename grsswk_sec`i' grsswk_sec
rename hrrate_sec_p1_`i' hrrate_sec_p1
rename hrrate_sec_p99_`i' hrrate_sec_p99
rename hourpay_sec`i' hourpay_sec
rename hourpay_sec_p1_`i' hourpay_sec_p1
rename hourpay_sec_p99_`i' hourpay_sec_p99
save imputed_sec`i'.dta, replace
}
clear

/* This loop appends all of the imputed`i'.dta files together to create the outlier report. */
use imputed_sec1.dta
forvalues i =2/`g' {
append using imputed_sec`i'.dta
}

/* Create value labels to annotate the outlier report. */
#delimit;
label define flaglab 
1 "cooks>0.04 & approx. 10-fold scaling error in hrrate_sec" 
2 "cooks> 0.04 & approx. 100-fold scaling error in hrrate_sec" 
3 "cooks>0.04 & netwk2>grsswk_sec" 
4 "cooks>0.04 & hrrate_sec outside of 1-99 percentile range of non-outlier distr." 
5 "cooks>0.04 & hourpay_sec outside of 1-99 percentile range of non-outlier distr." 
6 "cooks>0.04 & hrrate_sec & hourpay_sec outside of 1-99 percentile range of non-outlier distr."
7 "cooks > 0.04 and no obvious other problems"
8 "cooks > 0.04 and hourpay and hrrate difference > 0.33";
#delimit cr

forvalues i = 1/`g' {
label values flag`i' flaglab
}

/* Generate a single flag code variable for convenience. */
gen flag_code=.
forvalues i= 1/`g'{
replace flag_code= 1 if flag`i'==1
replace flag_code= 2 if flag`i'==2
replace flag_code= 3 if flag`i'==3
replace flag_code= 4 if flag`i'==4
replace flag_code= 5 if flag`i'==5
replace flag_code= 6 if flag`i'==6
replace flag_code= 7 if flag`i'==7
replace flag_code= 8 if flag`i'==8
}

/* Generate action_taken variable, just for the label.  Every flagj has the same action, no matter the loop number on which the outlier was identified. */
gen action_taken=.
forvalues i= 1/`g' {
replace action_taken=1 if flag`i'==1
replace action_taken=2 if flag`i'==2
replace action_taken=3 if flag`i'==3
replace action_taken=4 if flag`i'==4
replace action_taken=5 if flag`i'==5
replace action_taken=6 if flag`i'==6
replace action_taken=7 if flag`i'==7
replace action_taken=8 if flag`i'==8
}

#delimit;
label define action_taken_lab 
1 "Replaced hrrate_sec with hrrate_sec/10" 
2 "Replaced hrrate_sec with hrrate_sec/100" 
3 "Recalculated hourpay_sec as netwk2/(acthr2)" 
4 "Set hrrate_sec =." 
5 "Set hourpay_sec=."
6 "Set hrrate_sec=. & hourpay_sec=."
7 "set hrrate=."
8 "set hrrate=.";
#delimit cr

label values action_taken action_taken_lab

/* Now  order the variables for the final outlier report. */
order sernum cooks flag* flag_code action_taken hrrate_sec hrrate_sec_hat hourpay_sec hourpay_sec_hat grsswk_sec netwk2 grsswk_sec_hat acthr2 hrrate_sec_p1 hrrate_sec_p99

save "V:\Users\\${name}\\${location}\\${folder}\outlier-report_${time}_sec.dta", replace

/* Finally get rid of the individual imputed.dta files as the information within these is now in the outlier report. */
forvalues i =1/`g' {
erase imputed_sec`i'.dta
}

/* Now edit the pre_imputation.dta file to make sure variable names are as required for the doner process (undo unhelpful variable name changes arising from the code above). */
graph drop _all 
clear all
set more off
cd "V:\Users\\${name}\\${location}\\${folder}"

/* Preliminaries. */
use "pre_imputation_sec.dta", clear 

        rename e_hat_student sre_1
		rename hrrate_sec hrrate2
		egen p1= pctile(sre_1), p(1)                           /* Generate the 1st and 99th percentiles of the regression standardized residual. */
		egen p99= pctile(sre_1), p(99)
		rename y_hat allimput
		keep sernum age allimput hrrate2 sre_1 p1 p99           /* Drop all the variables not required. */
		gen donor=0
		replace donor=1 if (sre_1>p1 & sre_1<p99)              /* Donor cases lie between the 1st and 99th percentiles. */
		replace hrrate2=. if hrrate2<1                           /* If hrrate is less than 1, set it to missing. */
		save "${time}_fullset_sec.dta", replace               
		preserve 
		
/* Split the dataset according to the required agebands (which correspond to different wages). */	
		keep if age < 18                                         
			save "${time}_under18_sec.dta", replace
		restore                                                  
		preserve
		keep if age>17 & age<21
			save "${time}_18to20_sec.dta", replace 
		restore
		preserve
		keep if age >20 & age<25
		    save "${time}_21to24_sec.dta", replace
		restore 
		keep if age>=25
			save "${time}_25plus_sec.dta", replace 

/* Nearest Neighbour Method for 17 and below (teens) */
				use "${time}_under18_sec", clear              			
				preserve	
				keep if hrrate2==. & allimput !=.                        /* Create a set of receivers, those with a missing hrrate and valid predicted value. This is a subset of donor ==0 cases */
							save "${time}_under18receivers_sec", replace    
				restore								/* Restore full teenage set */
										keep if donor==1                 /* Select donor set only. */                
										sort allimput sernum
										forvalues j=0/9 {
											gen io`j' = hrrate2[_n-`j']   /* io0,..,ioj,.,io9 are working variables equal to the jth lag of hrrate. */																   							
										}
										
										gsort -allimput -sernum 	     /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {												
											gen hi`j' = hrrate2[_n-`j']	 /* hi0,...hij,...,hi9 are working variables equal to the jth lead of hrrate. */				   							
										}	
											
							append using ${time}_under18receivers_sec   /* Append the processed donor cases to the receiver set. */
							sort allimput sernum                         /* Sort on the regression predicted value. This allows for donation in the following steps */
										
										forvalues j=0/9 {
											replace io`j' = io`j'[_n-1] if missing(io`j')    /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen lonei`k' = io`j'        if missing(hrrate2)  /* The lonei1,...,loneik,...,lonei10 variables are the low imputed values defined only if hrrate is missing. */
										}

										gsort -allimput -sernum            					  /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {
											replace hi`j' = hi`j'[_n-1] if missing(hi`j')     /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen hinei`k' = hi`j'                               /* The hinei1,...,hineik,..., hinei10 variables are the low imputed values defined only if hrrate is missing. */
										}

										forvalues j=1/5  {                                      
											local k = 11 - `j'
											replace lonei`j' = hinei`k' if missing(lonei`j')
											replace hinei`j' = lonei`k' if missing(hinei`j')
										}

				drop io0 io1 io2 io3 io4 io5 io6 io7 io8 io9 hi0 hi1 hi2 hi3 hi4 hi5 hi6 hi7 hi8 hi9 lonei6 lonei7 lonei8 lonei9 lonei10 hinei6 hinei7 hinei8 hinei9 hinei10 /* Drop unneeded working variables. */
				                                                                      /* lonei1,...,lonei5, hinei1,...,hinei5 are the final nearest neighbour imputed variables. lags and leads 6-10 not required */
				save "${time}_under18allimput_sec.dta", replace    

				use "${time}_under18_sec.dta", clear   					 
				keep if allimput==. | (donor==0 & hrrate2>0 & hrrate2 !=.)     /* Select the other donor=0 cases, which were not donors because their standardized residual value is outside the 1st and 99th percentiles */
				append using ${time}_under18allimput_sec                    /* Add those cases to the dataset to the donors and receivers separated before.  You should now have all the observations from the teenage set. */
																			
									     forvalues j=1/5 {                   /* Sets the lonei1,...,loneik,...,lonei5 and hinei1,...,hineik,...hinei5 variables equal to hrrate if hrrate is not missing. */
											replace lonei`j' = hrrate2 if hrrate2 !=.  
											replace hinei`j' = hrrate2 if hrrate2 !=.	 														 
										 }
									
											sort sernum

save "${time}_under18hourlyrates_sec", replace       /* Save the final version of the dataset */

erase "${time}_under18allimput_sec.dta"                     /* Remove the three working datasets from the teenage processing. */
erase "${time}_under18_sec.dta"
erase "${time}_under18receivers_sec.dta"

/* Nearest neighbour method for 18-20. */
	use "${time}_18to20_sec.dta", clear              /* Select full young dataset. */			
				preserve	
				keep if hrrate2==. & allimput !=.                        /* Create a set of receivers, those with a missing hrrate and valid predicted value. This is a subset of donor ==0 cases */
							save "${time}_18to20receivers_sec.dta", replace    /* Save the receiver set. */		
				restore								/* Restore full young set */

										keep if donor==1                 /* Select donor set only. */                

										sort allimput sernum
										forvalues j=0/9 {
											gen io`j' = hrrate2[_n-`j']   /* io0,..,ioj,.,io9 are working variables equal to the jth lag of hrrate. */																   							
										}
										
										gsort -allimput -sernum 	     /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {												
											gen hi`j' = hrrate2[_n-`j']	 /* hi0,...hij,...,hi9 are working variables equal to the jth lead of hrrate. */				   							
										}	
											
							append using ${time}_18to20receivers_sec   /* Append the processed donor cases to the  receiver set. */
							sort allimput sernum                         /* Sort on the regression predicted value.  This allows for donation in the following steps */
										
										forvalues j=0/9 {
											replace io`j' = io`j'[_n-1] if missing(io`j')    /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen lonei`k' = io`j'        if missing(hrrate2)  /* The lonei1,...,loneik,...,lonei10 variables are the low imputed values defined only if hrrate is missing.*/
										
										}

										gsort -allimput -sernum            					  /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {
											replace hi`j' = hi`j'[_n-1] if missing(hi`j')      /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen hinei`k' = hi`j'                               /* The hinei1,...,hineik,..., hinei10 variables are the low imputed values defined only if hrrate is missing. */
										}

													forvalues j=1/5  {                                      
											local k = 11 - `j'
											replace lonei`j' = hinei`k' if missing(lonei`j')
											replace hinei`j' = lonei`k' if missing(hinei`j')
										}

				drop io0 io1 io2 io3 io4 io5 io6 io7 io8 io9 hi0 hi1 hi2 hi3 hi4 hi5 hi6 hi7 hi8 hi9 lonei6 lonei7 lonei8 lonei9 lonei10 hinei6 hinei7 hinei8 hinei9 hinei10 /* Drop unneeded working variables. */
				                                                                      /* lonei1,...,lonei5, hinei1,...,hinei5 are the final nearest neighbour imputed variables. lags and leads 6-10 not required  */
				save "${time}_18to20allimput_sec.dta", replace    

				use "${time}_18to20_sec.dta", clear   					 
				keep if allimput==. | (donor==0 & hrrate2>0 & hrrate2 !=.)     /* Select the other donor=0 cases, which were not donors because their standardized residual value is outside the 1st and 99th percentiles */
				append using ${time}_18to20allimput_sec                      /* Add those cases to the dataset to the donors and receivers separated before.  You should now have all the observations from the young set.*/
																			
									     forvalues j=1/5 {                   /* Sets the lonei1,...,loneik,...,lonei5 and hinei1,...,hineik,...hinei5 variables equal to hrrate if hrrate is not missing. */
											replace lonei`j' = hrrate2 if hrrate2 !=.  
											replace hinei`j' = hrrate2 if hrrate2 !=.	 														 
										 }
									
											sort sernum

save "${time}_18to20hourlyrates_sec", replace       /* Save the final version of the dataset */

erase "${time}_18to20allimput_sec.dta"              /* Remove the three working datasets from the young processing. */
erase "${time}_18to20_sec.dta"
erase "${time}_18to20receivers_sec.dta"

/* Nearest neighbour method for 21to24 */
	use "${time}_21to24_sec.dta", clear              /* Select full mature dataset. */			
				preserve	
				keep if hrrate2==. & allimput !=.                        /* Create a set of receivers, those with a missing hrrate and valid predicted value. This is a subset of donor ==0 cases */
							save "${time}_21to24receivers_sec", replace    /* Save the receiver set. */
							
				restore								/* Restore full mature set */

										keep if donor==1                 /* Select donor set only. */                

										sort allimput sernum
										forvalues j=0/9 {
											gen io`j' = hrrate2[_n-`j']   /* io0,..,ioj,.,io9 are working variables equal to the jth lag of hrrate. */																   							
										}
										
										gsort -allimput -sernum 	     /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {												
											gen hi`j' = hrrate2[_n-`j']	 /* hi0,...hij,...,hi9 are working variables equal to the jth lead of hrrate. */				   							
										}	
											
							append using ${time}_21to24receivers_sec   /* Append the processed donor cases to the receiver set.  */
							sort allimput sernum                         /* Sort on the regression predicted value. This allows for donation in the following steps */
										
										forvalues j=0/9 {
											replace io`j' = io`j'[_n-1] if missing(io`j')    /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen lonei`k' = io`j'        if missing(hrrate2)  /* The lonei1,...,loneik,...,lonei10 variables are the low imputed values defined only if hrrate is missing. */
										}

										gsort -allimput -sernum            					  /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {
											replace hi`j' = hi`j'[_n-1] if missing(hi`j')      /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen hinei`k' = hi`j'                               /* The hinei1,...,hineik,..., hinei10 variables are the low imputed values defined only if hrrate is missing. */
										}

										forvalues j=1/5  {                                      
											local k = 11 - `j'
											replace lonei`j' = hinei`k' if missing(lonei`j')
											replace hinei`j' = lonei`k' if missing(hinei`j')
										}

				drop io0 io1 io2 io3 io4 io5 io6 io7 io8 io9 hi0 hi1 hi2 hi3 hi4 hi5 hi6 hi7 hi8 hi9 lonei6 lonei7 lonei8 lonei9 lonei10 hinei6 hinei7 hinei8 hinei9 hinei10 /* Drop unneeded working variables. */
				                                                                      /* lonei1,...,lonei5, hinei1,...,hinei5 are the final nearest neighbour imputed variables. lags and leads 6-10 not required */
				save "${time}_21to24allimput_sec.dta", replace    

				use "${time}_21to24_sec.dta", clear   					 
				keep if allimput==. | (donor==0 & hrrate2>0 & hrrate2 !=.)     /* Select the other donor=0 cases, which were not donors because their standardized residual value is outside the 1st and 99th percentiles */
				append using ${time}_21to24allimput_sec                    /* Add those cases to the dataset to the donors and receivers separated before.  You should now have all the observations from the mature set. */
										
									     forvalues j=1/5 {                   /* Sets the lonei1,...,loneik,...,lonei5 and hinei1,...,hineik,...hinei5 variables equal to hrrate if hrrate is not missing.  */
											replace lonei`j' = hrrate2 if hrrate2 !=.  
											replace hinei`j' = hrrate2 if hrrate2 !=.	 														 
										 }
											sort sernum

save "${time}_21to24hourlyrates_sec", replace       /* Save the final version of the dataset */

erase "${time}_21to24allimput_sec.dta"                     /* Remove the three working datasets from the mature processing. */
erase "${time}_21to24_sec.dta"
erase "${time}_21to24receivers_sec.dta"

/* Nearest neighbour method for 25+ (National Living wage) */
	use "${time}_25plus_sec.dta", clear              /* Select full dataset. */			
				preserve	
				keep if hrrate2==. & allimput !=.                        /* Create a set of receivers, those with a missing hrrate and valid predicted value. This is a subset of donor ==0 cases */
							save "${time}_25plusreceivers_sec.dta", replace    /* Save the receiver set. */
							
				restore								/* Restore full set */

										keep if donor==1                 /* Select donor set only. */                

										sort allimput sernum
										forvalues j=0/9 {
											gen io`j' = hrrate2[_n-`j']   /* io0,..,ioj,.,io9 are working variables equal to the jth lag of hrrate. */																   							
										}
										
										gsort -allimput -sernum 	     /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {												
											gen hi`j' = hrrate2[_n-`j']	 /* hi0,...hij,...,hi9 are working variables equal to the jth lead of hrrate. */				   							
										}	
											
							append using ${time}_25plusreceivers_sec   /* Append the processed donor cases to the  receiver set. */
							sort allimput sernum                         /* Sort on the regression predicted value. This allows for donation in the following steps */
										
										forvalues j=0/9 {
											replace io`j' = io`j'[_n-1] if missing(io`j')    /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen lonei`k' = io`j'        if missing(hrrate2)  /* The lonei1,...,loneik,...,lonei10 variables are the low imputed values defined only if hrrate is missing. */
										}

										gsort -allimput -sernum            					  /* Invert the sort to get generate lead values using lag operation. */
										
										forvalues j=0/9 {
											replace hi`j' = hi`j'[_n-1] if missing(hi`j')     /* Replace io0,.ioj,..,io9 with first lag if ioj has a missing value (which receivers will). */
											local k = `j'+1
											gen hinei`k' = hi`j'                               /* The hinei1,...,hineik,..., hinei10 variables are the low imputed values defined only if hrrate is missing. */
										}

										forvalues j=1/5  {                                      
											local k = 11 - `j'
											replace lonei`j' = hinei`k' if missing(lonei`j')
											replace hinei`j' = lonei`k' if missing(hinei`j')
										}
			
				drop io0 io1 io2 io3 io4 io5 io6 io7 io8 io9 hi0 hi1 hi2 hi3 hi4 hi5 hi6 hi7 hi8 hi9 lonei6 lonei7 lonei8 lonei9 lonei10 hinei6 hinei7 hinei8 hinei9 hinei10 /* Drop unneeded working variables. */
				                                                                      /* lonei1,...,lonei5, hinei1,...,hinei5 are the final nearest neighbour imputed variables. lags and leads 6-10 not required */
				save "${time}_25plusallimput_sec.dta", replace    

				use "${time}_25plus_sec.dta", clear   					 
				keep if allimput==. | (donor==0 & hrrate2>0 & hrrate2 !=.)     /* Select the other donor=0 cases, which were not donors because their standardized residual value is outside the 1st and 99th percentiles */
				append using ${time}_25plusallimput_sec                    /* Add those cases to the dataset to the donors and receivers separated before.  You should now have all the observations from the mature set.*/
																			
									     forvalues j=1/5 {                   /* Sets the lonei1,...,loneik,...,lonei5 and hinei1,...,hineik,...hinei5 variables equal to hrrate if hrrate is not missing. */
											replace lonei`j' = hrrate2 if hrrate2 !=.  
											replace hinei`j' = hrrate2 if hrrate2 !=.	 														 
										 }
									
											sort sernum

save "${time}_25plushourlyrates_sec", replace       /* Save the final version of the dataset */

erase "${time}_25plusallimput_sec.dta"              /* Remove the three working datasets from the mature processing. */
erase "${time}_25plus_sec.dta"
erase "${time}_25plusreceivers_sec.dta"

/* Create Database for tables */
clear
use "${time}_25plushourlyrates_sec.dta"
append using "${time}_21to24hourlyrates_sec.dta"     /* Combine the four files and make a postdonor file, containing variables that have been treated */
append using "${time}_18to20hourlyrates_sec.dta"
append using "${time}_under18hourlyrates_sec.dta"

sort sernum 
save "${time}_postdonor_sec.dta", replace              /* Combined version of the imputed data. */

erase "${time}_21to24hourlyrates_sec.dta"     
erase "${time}_18to20hourlyrates_sec.dta"
erase "${time}_under18hourlyrates_sec.dta"
erase "${time}_25plushourlyrates_sec.dta"
erase "${time}_fullset_sec.dta"

/* Load in file prepared for imputation. Merge using the dataset we created in stage4, dropping variables that will be held in both files to avoid duplication */
use "pre_imputation_sec.dta", clear 
rename hrrate_sec d0

merge using "${time}_postdonor_sec"
drop allimput sre_1 d0 p1 p99 _merge

/* THESE WILL NEED CHANGING ON A HALF YEARLY BASIS, THESE ARE CORRECT FOR OCTOBER ${time} */
gen nmwu18= 4.00
gen nmw18to20= 5.55
gen nmw21to24= 6.95
gen nlw= 7.20

forvalues j=1/5 {                     
	local k = 6 - `j'
	gen nmwdon`j' = 1 if ((age <18 & lonei`k' !=. & lonei`k'<nmwu18) | (age> 17 & age< 21 & lonei`k' !=. & lonei`k'<nmw18to20) | (age> 20 & age< 25 & lonei`k' !=. & lonei`k'<nmw21to24) | (age>=25 & lonei`k' !=. & lonei`k'<nlw))
	replace nmwdon`j'=0 if ((age <18 & lonei`k' !=. & lonei`k' >=nmwu18) | (age>17 & age<21 & lonei`k' !=. & lonei`k'>=nmw18to20) | (age> 20 & age<25 & lonei`k' !=. & lonei`k'>=nmw21to24) | (age>=25 & lonei`k' !=. & lonei`k'>=nlw)) 
}

forvalues j = 6/10 {	
	local k = `j' - 5
gen nmwdon`j' = 1 if ((age <18 & hinei`k' !=. & hinei`k'<nmwu18) | (age> 17 & age< 21 & hinei`k' !=. & hinei`k'<nmw18to20) | (age> 20 & age< 25 & hinei`k' !=. & hinei`k'<nmw21to24) | (age>=25 & hinei`k' !=. & hinei`k'<nlw))
	replace nmwdon`j'=0 if ((age <18 & hinei`k' !=. & hinei`k' >=nmwu18) | (age>17 & age<21 & hinei`k' !=. & hinei`k'>=nmw18to20) | (age> 20 & age<25 & hinei`k' !=. & hinei`k'>=nmw21to24) | (age>=25 & hinei`k' !=. & hinei`k'>=nlw))  
}

/* Weights needupdating for usual data */
egen nmwdon= rowmean( nmwdon1 nmwdon2 nmwdon3 nmwdon4 nmwdon5 nmwdon6 nmwdon7 nmwdon8 nmwdon9 nmwdon10)
sum nmwdon
sum nmwdon [fweight=round(pwt17)]

/* create files for overall analysis
This is the key part to create the OVERALL dataset that includes everything. We merge the current dataset [2nd jobs] with the dataset we created earlier for main jobs. This then allows
us to use a whole dataset that includes 2nd and main jobs and all the other interesting variables */ 

preserve
append using "V:\Users\\${name}\\${location}\\${folder}\_${time}_readyfortables.dta"
save "${time}_overall.dta", replace 
restore 

/* Here we distingish between those that are second jobs and those that are main jobs by renaming variables with _s as second jobs */
foreach x of varlist _all {
	rename `x' `x'_s
} 

save "V:\Users\\${name}\\${location}\\${folder}\_${time}_readyfortables_sec.dta", replace

erase "${time}_postdonor_sec.dta" 
erase "low_pay16_sec.dta" 
erase "prep16_sec.dta"
erase "pre_imputation_sec.dta"
}
*
if "`1'" == "3" {
*** 1p TABLES ***
/* This code runs from 2014 to ${time} using Q4 data for each year. It just runs on a loop, so the same would be for if you were just doing it for ${time} Q4. Use macros to loop it over the different years - so they aren't important here.

Currently using 2014 to ${time}
In cumulative 1p bands by sex and ageband, and calculates them as a percentage of jobs in the job market 
Apprenticeships - not going to include them here, as cannot include them in below NMW 
Using secondary jobs. */
set more off
clear all
cd "V:\Users\\${name}\\${location}\\${folder}"

	use "_${time}_readyfortables.dta", replace
	
	/* dropping apprenticeships here */
	drop if apprcurr==1
	
/* open file and create 10 new variables, tpband1 to tpband10, this places the 10 donor rates of hrrate into 1p bands by truncating (rounding) them at 1 d.p. and adding 1p */
	/* this macro just acts as the 1p band, of which we truncate things to */
	local i = 0.01

/* These macros relate to the lonei and hinei variables */
forvalues j = 1/5 {
    local h = 6 - `j'
         gen tpband`j'= `i'*ceil(lonei`h'/`i')
}
 
forvalues j = 6/10 {
    local h = `j' - 5
	    gen tpband`j'= `i'*ceil(hinei`h'/`i')
}

preserve

/* Generate count variable as an indication of frequency 
Collapse the data in order to allow to save weighted dataset of frequency by sex and ageband */

gen count0=1
collapse (count) count0 [fweight=piwt17], by (sex ageband)
save "1p_aggr0.dta", replace
restore 

local j=1
/* The loop here basically recodes tpband into tpdist, replace vaues of 2.90 or below with 2.90.
The same occurs for 10p. These are then saved [collapsed] as each individual dataset corresponding to each version of tpdist. Each version of the loop generates a different version 
of count, which represents the freq of that loop */

while (`j'<11) {
    recode tpband`j' (0/2.9=2.9) (10.0/10000=10), gen(tpdist`j')
	preserve
	gen count`j'=1
    collapse (count) count`j' [fweight=piwt17], by (sex ageband tpdist`j')
	rename tpdist`j' tpdist
	keep if tpdist !=.
	save "1p_aggr`j'.dta", replace
	
	restore 
	local j= `j'+1
	}

/* Second jobs		
The same methodogly and processing for second jobs - main difference is 2nd jobs are weighted by population pwt rather than piwt */
 use "_${time}_readyfortables_sec.dta", replace
local i = 0.01

forvalues j = 1/5 {
    local h = 6 - `j'
         gen tpband`j'_s= `i'*ceil(lonei`h'/`i')
}

forvalues j = 6/10 {
    local h = `j' - 5
	    gen tpband`j'_s= `i'*ceil(hinei`h'/`i')
}

preserve

gen count0_s=1
collapse (count) count0_s [fweight=pwt17], by (sex ageband)
rename sex_s sex
rename ageband_s ageband
save "1p_aggr0_s.dta", replace
restore

local j=1
while (`j'<11) {

    recode tpband`j'_s (0/2.9=2.9) (10.0/10000=10), gen(tpdist`j'_s)
	preserve
	gen count`j'_s=1
    collapse (count) count`j'_s [fweight=pwt17], by (sex_s ageband_s tpdist`j'_s)
	rename tpdist`j'_s tpdist
	rename sex_s sex
	rename ageband_s ageband 
	keep if tpdist !=.
	save "1p_aggr`j'_s.dta", replace
	
	restore 
	local j= `j'+1
	}

/* load in first dataset from main jobs */
use "1p_aggr1.dta", clear

/* Then merge all the different datasets from main jobs together. We use j=2 here as aggr1 is already loaded in. We then merge the 3 variables which we need, dropping _merge variable */
local j=2

while (`j'<11) {
    merge 1:1 sex ageband tpdist using "1p_aggr`j'.dta"
	local j= `j'+1
	drop _merge
	}

/* Then merge the main jobs with the 2nd jobs datasets */ 
local j=1

while (`j'<11) {
    merge 1:1 sex ageband tpdist using "1p_aggr`j'_s.dta"
	local j= `j'+1
	drop _merge
	}

/* Replace count equal to 0 if they include a missing count, this allows us to create frequencies */	
local j=1 

while (`j'<11) {
    replace count`j'=0 if missing(count`j')
	replace count`j'_s=0 if missing(count`j'_s)
	local j= `j'+1
	}

/* This starts the main set up of the output here */
/* Firstly, calculate the mean of the weighted frequencies (counts) of donated hrrate values */

egen average= rowmean( count1 count2 count3 count4 count5 count6 count7 count8 count9 count10 )
egen average_s= rowmean( count1_s count2_s count3_s count4_s count5_s count6_s count7_s count8_s count9_s count10_s)
preserve 

/* Collapse the data to obtain sum of averages for second and main jobs by ageband and sex */
collapse (sum) average (sum) average_s, by (sex ageband)
rename average summain
rename average_s sum2nd
save "1p_agrr.dta", replace
restore 

/* Generate the sum of the weighted number of first jobs ("summain") 
Generate the sum of the weight number of second jobs ("sum2nd") broken down by age and sex */ 
egen summain= sum(average), by (sex ageband) 
egen sum2nd= sum(average_s), by (sex ageband)

/* Append in the files we created at the beginning for an overall perspective */
append using 1p_aggr0
append using 1p_aggr0_s

/* Scale the weighted frequencies of first jobs in each payband up to the total working population within each sex/ageband domain by computing a new variable adjmain, which is the mean
of the weighted frequencies of the 10 donated values of hrrate multiplied by the sum of weighted frequencies of jobs including those without imputed hrrate data, divided by the sum of
weighted frequencies of those in the database with imputed hrrate data */ 
egen freq0= sum(count0), by(sex ageband) 
egen freq0_s= sum(count0_s), by(sex ageband) 
drop if missing(summain)
drop count0 count0_s

gen adjmain= (average*freq0)/summain
gen adj2nd= (average_s*freq0_s)/sum2nd
replace freq0_s=0 if missing(adj2nd)
replace adj2nd=0 if missing(adj2nd)

/* Add the frequencies of first and second jobs */
gen adjall= adjmain + adj2nd

/* Calculate the cumulative weighted frequencies of the number of jobs within the sex/ageband domains */
gen cumfreq = .

/* These loops just jump through each ageband for male */
local j= 0
    while `j' < 4 {
       replace cumfreq = sum(adjall) if ageband==`j' & sex==1
	local j= `j' + 1
   }
   
/* These loops just jump through each ageband for female */  
local j=0
    while `j' < 4 {
        replace cumfreq = sum(adjall) if ageband==`j' & sex==2
	local j= `j' + 1
	}

gen percent= cumfreq*100/(freq0+freq0_s)
save "table_1p", replace

/* The code here creates individual datasets for each different sex and ageband. First set of code is for Males and then females. 
These datasets will then be merged together for an overall */

/* Male */
local f= "female"
local m= "male"

local j =0
	while `j' < 4 {
	
foreach var in `m'_u18 `m'_18to20 `m'_21to24 `m'_over25 {
		preserve
		keep if sex==1 & ageband==`j'
		rename cumfreq `var'level
		rename percent `var'rate
		keep tpdist `var'level `var'rate
		save "1p_`var'", replace
	restore
			local j= `j' + 1	
	} 
}

/* Female */
local j =0
	while `j' < 4 {
	
		foreach var in `f'_u18 `f'_18to20 `f'_21to24 `f'_over25 {

		preserve
		keep if sex==2 & ageband==`j'
		rename cumfreq `var'level
		rename percent `var'rate
		keep tpdist `var'level `var'rate
		save "1p_`var'", replace
		restore
			local j= `j' + 1
		}
}

/* Merge using created files to obtain overall files */
use "1p_male_u18", clear

foreach var in `m'_u18 `f'_u18 `m'_18to20 `f'_18to20 `m'_21to24 `f'_21to24 `m'_over25 `f'_over25 {
merge 1:1 tpdist using "1p_`var'"
drop _merge
}	

/* Need to fill in the gaps in the cumulative table, using lag function if missing a value, take the value from the above observation */
sort tpdist 

foreach var of varlist *male* *female* {
	replace `var'= `var'[_n-1] if missing(`var')
}

order tpdist *level* *rate*

/* Delete all unneccesary files */
local list : dir . files "*1p*.dta"
foreach f of local list {
erase "`f'"
}

/* This is a final 1p table dataset */
save "1p_finaltables_`g'.dta"

/* Export into excel where there is an automated process that produces the 1p tables */
export excel using "V:\Users\\${name}\\${location}\\${folder}\JR_1p tables.xls", sheetmodify sheet("2016") cell(B2) firstrow(var) nolabel missing(.)
}

*

if "`1'" == "4" {
/* NMWDON analysis just for ${time} Q4. Estimates of percentages of jobs paying below NMW
We only created this for 16+ due to our time series analysis being focused around this code.

Description: 
This part of code allows a automated "tab" to be exported in excel the code works by collapsing the data for the variables we would like to "tab". We then reshape the data, 
replacing any missing observations as cannot reshape using missing variables. By saving this data then as a .dta file we can merge the files and export them in excel.

Main jobs only */
clear all
set more off
cd "V:\Users\\${name}\\${location}\\${folder}"
use "V:\Users\\${name}\\${location}\\${folder}\_${time}_readyfortables.dta", clear

local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' inds07m)
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(inds07m) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16industry`j'.dta", replace
local j= `j'+1
restore 
    }

preserve 
local j=2
use "plus_16industry1.dta", clear
while (`j'<11) {

    merge 1:1 inds07m using "plus_16industry`j'.dta"
	local j= `j'+1
	drop _merge
	}
export excel using "16playaround.xls", sheet("industry") firstrow(variables) sheetmodify cell(A1) 

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}
restore 

/* Occupation */
local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' sc10mmj)
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(sc10mmj) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16occupation`j'.dta", replace
local j= `j'+1
restore 
    }

preserve
local j=2
use "plus_16occupation1.dta", clear
while (`j'<11) {
    merge 1:1 sc10mmj using "plus_16occupation`j'.dta"
	local j= `j'+1
	drop _merge
	}
export excel using "16playaround.xls", sheet("occupation") firstrow(variables) sheetmodify cell(A1) 

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}

/* Employeee size */
restore 

local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' mpnr02)
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(mpnr02) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16employeesize`j'.dta", replace
local j= `j'+1
restore 
    }

preserve
local j=2
use "plus_16employeesize1.dta", clear
while (`j'<11) {
    merge 1:1 mpnr02 using "plus_16employeesize`j'.dta"
	local j= `j'+1
	drop _merge
	}

export excel using "16playaround.xls", sheet("employeesize") firstrow(variables) sheetmodify cell(A1)

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}
restore 

/* Regional breakdown */
local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' govtor)
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(govtor) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16region`j'.dta", replace
local j= `j'+1
restore 
    }

preserve
local j=2
use "plus_16region1.dta", clear
while (`j'<11) {
    merge 1:1 govtor using "plus_16region`j'.dta"
	local j= `j'+1
	drop _merge
	}
export excel using "16playaround.xls", sheet("region") firstrow(variables) sheetmodify cell(A1)

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}
restore

/* Ethnicity */
local j=1 
while (`j'<11) {
preserve 
    gen freq=1
	collapse (count) freq [fweight=piwt17], by (nmwdon`j' ethukeul)
	replace nmwdon`j'=2 if missing(nmwdon`j')
	reshape wide freq, i(ethukeul) j(nmwdon`j')
	drop freq2
	   foreach x of varlist _all {
	   replace `x' = 0 if missing(`x')
	       }
	rename freq0 nmwdon`j'_0
	rename freq1 nmwdon`j'_1
	gen total`j'= nmwdon`j'_0 + nmwdon`j'_1
	
save "plus_16ethnicity`j'.dta", replace
local j = `j'+1
restore
    }

preserve
local j=2
use "plus_16ethnicity1.dta", clear
while (`j'<11) {
    merge 1:1 ethukeul using "plus_16ethnicity`j'.dta"
	local j= `j'+1
	drop _merge
	}

export excel using "16playaround.xls", sheet("ethnicity") firstrow(variables) sheetmodify cell(A1)

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}
restore 

/* Level of Qualification */
local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' levqul15)
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(levqul15) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16qualifications`j'.dta", replace
local j= `j'+1
restore 
    }

preserve
local j=2

use "plus_16qualifications1.dta", clear
while (`j'<11) {
    merge 1:1 levqul15 using "plus_16qualifications`j'.dta"
	local j= `j'+1
	drop _merge
	}

export excel using "16playaround.xls", sheet("qualifications") firstrow(variables) sheetmodify cell(A1) 

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}

/* Disability */
restore 
local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' discurr13)
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(discurr13) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16disability`j'.dta", replace
local j= `j'+1
restore 
    }

preserve
local j=2
use "plus_16disability1.dta", clear
while (`j'<11) {
    merge 1:1 discurr13 using "plus_16disability`j'.dta"
	local j= `j'+1
	drop _merge
	}

export excel using "16playaround.xls", sheet("disability") firstrow(variables) sheetmodify cell(A1) 

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}

/* Qualifications */
restore 
local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' levqul15a)
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(levqul15a) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16qualificationsa`j'.dta", replace
local j= `j'+1
restore 
    }

preserve	
local j=2
use "plus_16qualificationsa1.dta", clear
while (`j'<11) {
    merge 1:1 levqul15a using "plus_16qualificationsa`j'.dta"
	local j= `j'+1
	drop _merge
	}

export excel using "16playaround.xls", sheet("qualificationsa") firstrow(variables) sheetmodify cell(A1)

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}

/* Level of Qualification */
restore 
local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' levqul15)
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(levqul15) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16qualifications`j'.dta", replace
local j= `j'+1

restore 
    }

preserve 
local j=2
use "plus_16qualifications1.dta", clear
while (`j'<11) {
    merge 1:1 levqul15 using "plus_16qualifications`j'.dta"
	local j= `j'+1
	drop _merge
	}

export excel using "16playaround.xls", sheet("qualifications") firstrow(variables) sheetmodify cell(A1) 

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}

/* Disability A */
restore 
local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' discurr13a)
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(discurr13a) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16disability`j'.dta", replace
local j= `j'+1
restore 
    }

preserve
local j=2
use "plus_16disability1.dta", clear
while (`j'<11) {
    merge 1:1 discurr13a using "plus_16disability`j'.dta"
	local j= `j'+1
	drop _merge
	}
export excel using "16playaround.xls", sheet("disabilitya") firstrow(variables) sheetmodify cell(A1) 

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}

/* Zero Hour Contracts */
restore 
local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' flexw7 )
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(flexw7) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1

save "plus_16zerohour`j'.dta", replace
local j= `j'+1
restore 
    }

preserve 
local j=2
use "plus_16zerohour1.dta", clear
while (`j'<11) {
    merge 1:1 flexw7 using "plus_16zerohour`j'.dta"
	local j= `j'+1
	drop _merge
	}

export excel using "16playaround.xls", sheet("zero_hour") firstrow(variables) sheetmodify cell(A1) 

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}

/* full time, part time */
restore 
local j=1
while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' ftptwk )
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(ftptwk) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1
	
save "plus_16zerohour`j'.dta", replace
local j= `j'+1
restore 
    }

preserve
local j=2
use "plus_16zerohour1.dta", clear
while (`j'<11) {
    merge 1:1 ftptwk using "plus_16zerohour`j'.dta"
	local j= `j'+1
	drop _merge
	}
export excel using "16playaround.xls", sheet("fulltime_parttime") firstrow(variables) sheetmodify cell(A1) 

local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}

/* Hours */
restore 

gen hours=.
replace hours=1 if bushr <=10
replace hours=2 if bushr > 10 & bushr <=20
replace hours=3 if bushr > 20 & bushr <=30
replace hours=4 if bushr > 30 & bushr <=40
replace hours=5 if bushr > 40

label define hours 1 "1-10" 2 "11-20" 3 "21-30" 4 "31-40" 5 "41+"
local j=1

while (`j'<11) {
preserve 
    gen freq=1
    collapse (count) freq [fweight=piwt17], by (nmwdon`j' hours )
    replace nmwdon`j'= 2 if missing(nmwdon`j') 
    reshape wide freq, i(hours) j(nmwdon`j')
    drop freq2
        foreach x of varlist _all {
        replace `x' = 0 if missing(`x')
             }
	rename freq0 nmwdon`j'_0
    rename freq1 nmwdon`j'_1
    gen total`j'= nmwdon`j'_0 + nmwdon`j'_1
save "plus_16hours`j'.dta", replace
local j= `j'+1
restore 
    }

preserve
local j=2
use "plus_16hours1.dta", clear
while (`j'<11) {
    merge 1:1 hours using "plus_16hours`j'.dta"
	local j= `j'+1
	drop _merge
	}

export excel using "16playaround.xls", sheet("hours") firstrow(variables) sheetmodify cell(A1) 
local list : dir . files "*plus_16*.dta"
    foreach f of local list {
    erase "`f'"
}
restore 
} 
*

if "`1'" == "5" { 
/* note: not currently used in analysis */

/* Creates the "Overall" tab for main jobs in section for the beginning of Stage 14. Use similar for second jobs and append. */
clear
cd "V:\Users\\${name}\\${location}\\${folder}"
set more off
use "V:\Users\\${name}\\${location}\\${folder}\_${time}_readyfortables.dta", clear

/* Main jobs */
gen filter=0
replace filter=1 if inds07m > 0 & inds07m < 20
label variable filter "inds07m > 0 & inds07m < 20"
label define filter 0 "not selected" 1 "selected"

tabulate ageband, generate(dageband)   /* Calculate ageband dummies.  These will get sum-collapsed later to give the required crosstabs .*/
rename dageband1 below_18
rename dageband2 _18_20
rename dageband3 _21_24
rename dageband4 _25_plus
gen _16_plus = 0
replace _16_plus = 1 if (age>=16)
gen _18_plus = 0
replace _18_plus = 1 if (age>=18)

keep if filter==1                      
local counter  = 1                     /* Keeps track of the loop number for saving working files.  The counter will increment by 1 when each variable of interest's table has been completed
										and saved to a separate file, wrking`counter'.dta */

foreach vbl of varlist inds07m sc10mmj mpnr02 govtor levqul15 ethukeul discurr13 cryox7a natox7a discurr13a levqul15a {    /* Referred to as the "variable of interest". */
	preserve	   /* Preserve so we can easily go back to the underlying data after the collapse sum.   See the restore later in the code. */
		collapse (sum) below_18 _18_20 _21_24 _25_plus _16_plus _18_plus [fweight=piwt16], by(`vbl')       /* Calculate the sum of the ageband indicators, weighted and by the variable of interest. */
		rename `vbl' cate                                                                                  /* This replaces the observation entries of the variable of interest with the (string) label.*/
		decode cate, gen(category)                                                                         /* String labels will be contained in a variable called "category". */
		drop cate	
		gen variable = "`vbl'"                                                                             /* A variable to remind us of the original variable name in the final output. */
		
		drop if category ==""   /* Drop any missings (observations not assigned a category for the particular variable).*/
		save "wrking`counter'.dta", replace             /* Save the table for the variable of interest. */
		
		collapse (sum) below_18 _18_20 _21_24 _25_plus _16_plus _18_plus     /* This creates a "Total" row for the table of the variable of interest, using yet another collapse. */
		gen category = "Total"  
		gen variable = "`vbl'"
	save tots.dta, replace                                                   /* Save the single "Total" row as "tots.dta", and then append it back on to the (bottom of the) table.*/                
	clear
	use "wrking`counter'.dta"
	append using tots.dta
	
	gen job = "main job"                               /* A useful column for all of the final "main job" tables, for reference. */
	save "wrking`counter'.dta", replace                  /* Save the final version of the table for the variable of interest, which now has "Missing" row (or corresponding padded row) 
															if required, and a "Total" row. */
	erase tots.dta                                           
	local counter = `counter' + 1                        /* And on to the table for the next variable of interest... */	
	restore
}
local max_c = `counter' - 1                             /* The rest of the Main Jobs section is appending all of the tables for the variable of interest together into a column, with some
															blanks space between each table. */
                                                        /* It also cleans up by erasing the wrking.dta files. */
clear
use wrking1.dta               
local ssize = _N +3                                     /* There will be three rows between each table. */
set obs `ssize'
erase wrking1.dta

forvalues i = 2/ `max_c' {
	append using "wrking`i'.dta"	
	local ssize = _N + 3
	set obs `ssize'
	erase "wrking`i'.dta"
}
order job variable category                            /* Put these variables on the left hand side of the file in that order. */
gen blank = ""
save main_jobs_overall.dta, replace                     /* Save the main jobs rows. */


/* Second jobs */ 
/* The code for second jobs is essentially a repeat of main jobs, except with some different variables of interest (and hence tables).  Note that variable names are also different, having 
an "_s" suffix. */
use "V:\Users\\${name}\\${location}\\${folder}\_${time}_readyfortables_sec.dta", clear     /* The second jobs input dataset is different from the main jobs one. */

gen filter=0
replace filter=1 if inds07s_s > 0 & inds07s_s < 20
label variable filter "inds07s_s > 0 & inds07s_s < 20"
label define filter 0 "not selected" 1 "selected"
keep if filter==1

tabulate ageband, generate(dageband)
rename dageband1 below_18
rename dageband2 _18_20
rename dageband3 _21_24
rename dageband4 _25_plus
gen _16_plus = 0
replace _16_plus = 1 if (age_s>=16)
gen _18_plus = 0
replace _18_plus = 1 if (age_s>=18)

keep if filter==1
local bandvars  = "below_18 _18_20 _21_24 _25_plus _16_plus _18_plus"
local rows  = 5
local counter  = 1

foreach vbl of varlist inds07s_s sc10smj_s mpnsr02_s govtor_s levqul15_s discurr13_s sex_s cryox7a_s natox7a_s discurr13a_s levqul15a_s  {
	preserve	
		collapse (sum) below_18 _18_20 _21_24 _25_plus _16_plus _18_plus [fweight=pwt16_s], by(`vbl')
		rename `vbl' cate
		decode cate, gen(category)
		drop cate	
		gen variable = "`vbl'"
		drop if category ==""   /* Drop any missings (observations not assigned a category for the particular variable). */
		save "wrking`counter'.dta", replace              
		collapse (sum) below_18 _18_20 _21_24 _25_plus _16_plus _18_plus
		gen category = "Total"
		gen variable = "`vbl'"
	save tots.dta, replace
	clear
	use "wrking`counter'.dta"
	append using tots.dta
	gen job = "second job"
	replace category = "Missing" if category ==""
	save "wrking`counter'.dta", replace
	erase tots.dta
	local counter = `counter' + 1
	restore
}
local max_c = `counter' - 1
clear
use wrking1.dta
local ssize = _N +3
set obs `ssize'
erase wrking1.dta
forvalues i = 2/ `max_c' {
	append using "wrking`i'.dta"	
	local ssize = _N + 3
	set obs `ssize'
	erase "wrking`i'.dta"
}
order job variable category
save second_jobs_overall.dta, replace

/* Output to Excel */
/* Finally, output the Excel files into the same tab of the same Excel sheet.  Note the different starting columns (the "cell()" option), so main jobs and second jobs can go side-by-side. */
use main_jobs_overall.dta, clear
export excel using "_${time}_tab.xlsx", sheet("test_a") firstrow(variables) sheetmodify cell(A1) 

use second_jobs_overall.dta, clear
export excel using "_${time}_tab.xlsx", sheet("test_a") firstrow(variables) sheetmodify cell(K1) 
}
}
*

/* Removes the data series stored in stata */
erase "V:\Users\\${name}\\${location}\\${folder}\_${time}_readyfortables.dta"
erase "V:\Users\\${name}\\${location}\\${folder}\_${time}_readyfortables_sec.dta"
erase "V:\Users\\${name}\\${location}\\${folder}\1p_finaltables_5.dta"
erase "V:\Users\\${name}\\${location}\\${folder}\main_jobs_overall.dta"
erase "V:\Users\\${name}\\${location}\\${folder}\\${time}_overall.dta"
erase "V:\Users\\${name}\\${location}\\${folder}\outlier_report_${time}.dta"
erase "V:\Users\\${name}\\${location}\\${folder}\outlier-report_${time}_sec.dta"
erase "V:\Users\\${name}\\${location}\\${folder}\second_jobs_overall.dta"
