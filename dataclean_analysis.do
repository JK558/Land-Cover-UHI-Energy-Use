cd "~/Dropbox/UHI"
clear
unicode analyze *.dta
unicode encoding set "GB18030" 
unicode retranslate CRECS2012年数据.dta, transutf8
unicode retranslate data09.dta

use "CRECS2012年数据.dta", clear

*export excel using "/Users/JK/Dropbox/UHI/data2012.xlsx", firstrow(varlabels) replace
*export excel using "/Users/JK/Dropbox/UHI/data2012.xlsx", firstrow(variables) nolabel replace

* display serial properly
format %20.0g serial
*help misstable
* tabulate missing varible
misstable summarize serial // no missing values
*misstable patterns serial
*misstable tree serial
*misstable summarize serial, all

*isid -- Check for unique identifiers
isid index  //Yes
isid serial //No
duplicates report serial
duplicates list serial
duplicates tag serial, generate (serial_dup)
/* think about edit serial to make it unique*/

* possible varible needed
/*index serial respondent longitude_deg longitude_min longitude_sec 
latitude_deg latitude_min latitude_sec a1 a3
b1-b14 b16-b26
*/

* check outliers for lat/long
codebook longitude_deg
codebook latitude_deg
codebook longitude_min //yes
codebook latitude_min //yes
codebook longitude_sec //yes
codebook latitude_sec //yes
* gsort -longitude_sec //sort longtitude desceding

* replace outliers (missing values included) with 0
replace longitude_min = 0 if longitude_min>60
replace longitude_sec = 0 if longitude_sec>60
replace latitude_min = 0 if latitude_min>60
replace latitude_sec = 0 if latitude_sec>60

generate longitude = longitude_deg +( longitude_min /60)+( longitude_sec /3600), after(no)
generate latitude = latitude_deg +( latitude_min /60)+( latitude_sec /3600), after(no)
sort index


*export delimited index latitude_deg longitude_deg using "latlong", novarnames nolabel replace
// export lat and long to Lat_Long.csv
*export delimited index latitude longitude using "Lat_Long", novarnames nolabel replace

rename (a1 b1 f1a) (fsize urban income)
keep index-county latitude longitude fsize a2_1_a-a2_1_k urban b2-b14 ///
b16-b26 income f3_1_a-f3_13_a f3_1_d-f3_13_d

label variable b2 "rise"
label variable b3 "level"
label variable b5 "movein"
label variable b7 "ownership"
label variable b8 "ownship type"
label variable b9 "built year"
label variable b10 "wall material"
label variable b11 "roof material"
label variable b12 "height"
label variable b13 "size structure"
label variable b14 "size used"
label variable b16 "bathroom"
label variable b17 "balcony"
label variable b22 "basement dummy"
label variable b23 "attic dummy"
label variable b24 "garrage dummy"
label variable income "2012 household income after tax"
label variable f3_1_a "Jan electricity use"
label variable f3_1_d "Jan electricity bill"

*save "/Users/JK/Dropbox/UHI/household.dta", replace
*check if f3_a_13 f3_d_13 is equal to annual total, yes
*egen f3_a_total =  rowtotal(f3_1_a-f3_12_a) 
*egen f3_d_total =  rowtotal(f3_1_d-f3_12_d), after(f3_13_d)

rename f3_1_a f3_a_1
rename f3_2_a f3_a_2
rename f3_3_a f3_a_3
rename f3_4_a f3_a_4
rename f3_5_a f3_a_5
rename f3_6_a f3_a_6
rename f3_7_a f3_a_7
rename f3_8_a f3_a_8
rename f3_9_a f3_a_9
rename f3_10_a f3_a_10
rename f3_11_a f3_a_11
rename f3_12_a f3_a_12

rename f3_1_d f3_d_1
rename f3_2_d f3_d_2
rename f3_3_d f3_d_3
rename f3_4_d f3_d_4
rename f3_5_d f3_d_5
rename f3_6_d f3_d_6
rename f3_7_d f3_d_7
rename f3_8_d f3_d_8
rename f3_9_d f3_d_9
rename f3_10_d f3_d_10
rename f3_11_d f3_d_11
rename f3_12_d f3_d_12

reshape long f3_a_ f3_d_, i(index) j(month)
*reshape wide f3_a_ f3_d_, i(index) j(month)
drop f3_13_a f3_13_d
order f3_a_ f3_d_ , after(month)
order income urban, after (fsize)

rename f3_a_ elec_use
rename f3_d_ elec_bill
gen price = elec_bill/elec_use, after (elec_bill)

save "/Users/JK/Dropbox/UHI/household.dta", replace
rename index ID
merge 1:1 ID month using "/Users/JK/Dropbox/UHI/lst2012/LST_pre.dta"
drop _merge
merge m:1 ID  using "/Users/JK/Dropbox/UHI/landcover2012/LC_pre.dta"
drop _merge
merge m:1 ID  using "/Users/JK/Dropbox/UHI/vegetation-continuous-fields-2012/VGF_pre.dta"
drop _merge

save "/Users/JK/Dropbox/UHI/master.dta", replace
* just to make sure sort by ID, month
sort ID month
* create categorical "province_n" variable from str variable 'province'
encode province, generate(province_n)
tab province_n, missing nolabel
tab province_n, missing 

* north china, central,south china
gen north=province_n, after (province_n)
recode   north (1 6 9 18 20 26=1) (2 12 13 15 19 21 23 24 =2)
replace north=0 if north>2
tab province_n north
label variable north "north china"
label define northchina 0 "North" 1 "Central" 2 "South"
label values north northchina

* summer dummy
gen summer=0
replace summer=1 if month>3 & month<10
* single family home dummy
* b2 rise
gen sf=0
replace sf=1 if b2 ==1

*newly buildt dummy (after year 1990)
gen new=., after(b9)
replace new=1 if b9>5 & b9<9
replace new=0 if b9<6
tab new b9,mi

histogram DD_monthly
graph export "/Users/JK/Dropbox/UHI/DDhisto.eps", as(eps) preview(off) replace
gen DD_sq = DD_monthly^2

label variable DD_sq "Degree Days^2"
label variable sf "Single Family House"
label variable elec_use "Electricity Consumption"
label variable fsize "Household Size"
label variable DD_monthly "Degree Days"
label variable province_n "Province"
label variable NonVege "NonVege Percentage"

* create value label for variable 'urban'
label copy B1 b1
label define b1 1 "city", modify
label define b1 2 "town", modify
label define b1 3 "rural", modify
label values urban b1
* Or another way
*label define b1 1 "city" 2 "town" 3 "rural"
*label values urban b1

* elec_use missing dummy
gen m_elec_use=0
replace m_elec_use=1 if elec_use==.

by ID: gen m_elec_use_sum = sum(m_elec_use)
by ID: egen m_elec_use_tot = total(m_elec_use)
order m_elec_use m_elec_use_sum m_elec_use_tot, after (elec_use)

graph box DD_monthly, over(month) legend(on)
graph export "/Users/JK/Dropbox/UHI/DDmonthly.eps", as(eps) preview(off) replace
graph save Graph "/Users/JK/Dropbox/UHI/DDmonthly.gph", replace

*consilidate land type
*LC_Type3
gen LC_Type3=., after (LC_Type2)
* water
replace LC_Type3=4 if LC_Type2 ==0 | LC_Type2==11
* forest/savanna
replace LC_Type3=1 if LC_Type2 >0 & LC_Type2<10
* grassland
replace LC_Type3=2 if LC_Type2 ==10
* crop land
replace LC_Type3=3 if LC_Type2 ==12 | LC_Type2==14
* urban built up
replace LC_Type3=0 if LC_Type2 ==13
* barren
replace LC_Type3=5 if LC_Type2 ==15
*label variable north "north china"
label define LandCover 0 "Urban/Built up" 1 "forest/shrubland/savanna" ///
 2 "grassland" 3"cropland" 4"water" 5"barren" 
label values LC_Type3 LandCover

*regroup land type 
*LC_Type4
gen LC_Type4=., after (LC_Type3)
* urban built up
replace LC_Type4=0 if LC_Type3 ==0
* vege
replace LC_Type4=1 if LC_Type3 == 1 | LC_Type3 == 3|LC_Type3 == 2
* water
replace LC_Type4=4 if LC_Type3 ==4
* barren
replace LC_Type4=5 if LC_Type3 ==5

*regroup land type 
*LC_Type5
gen LC_Type5=., after (LC_Type3)
* urban built up
replace LC_Type5=0 if LC_Type3 ==0
* natural
replace LC_Type5=1 if LC_Type3 == 1 | LC_Type3 == 2|LC_Type3 == 4
* man made
replace LC_Type5=3 if LC_Type3 ==3
* barren
replace LC_Type5=5 if LC_Type3 ==5

***Regression***
*b7 ownership, 
*b13 size, 
*b9 built year

*control 1: 
*fsize i.income i.urban i.b7 i.b13 i.b9 i.month
*control 2
*fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n

************
**LC_Type2 
************
*both LC and TC
reg elec_use DD_monthly i.LC_Type2 c.DD_monthly#i.LC_Type2 Tree_Cover c.DD_monthly#c.Tree_Cover ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month, vce(robust)
*only TC 
reg elec_use DD_monthly  Tree_Cover c.DD_monthly#c.Tree_Cover ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month, vce(robust)

reg elec_use DD_monthly  Tree_Cover c.DD_monthly#c.Tree_Cover ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month if elec_use < 2000, vce(cluster ID) 
*only LC
reg elec_use DD_monthly  i.LC_Type2 c.DD_monthly#i.LC_Type2 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month if elec_use < 2000, vce(cluster ID) 
 
reg elec_use DD_monthly  i.LC_Type2 c.DD_monthly#i.LC_Type2 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month if elec_use < 2000, vce(robust)  
 
************************
*LC_Type3, 0 "Urban/Built up" 1 "forest/shrubland/savanna" 2 "grassland" 3"cropland" 4"water" 5"barren" 
************************

reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month if elec_use < 2000, vce(robust)
 
reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month , vce(robust) 

**No UHI 
reg elec_use DD_monthly  ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month if elec_use < 2000, vce(robust)
 
reg elec_use DD_monthly  ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if elec_use < 2000, vce(robust) 

**more LC_Type3, with province_n
**$$
reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if elec_use < 2000, vce(robust)  

reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if m_elec_use_tot <6 & elec_use < 2000, vce(robust)
 
reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if m_elec_use_tot <7 & elec_use < 2000, vce(robust)   

reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if (LC_Type3==0|LC_Type3==1)&elec_use < 2000, vce(robust)  

reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if (LC_Type3==0|LC_Type3==2)&elec_use < 2000, vce(robust)  

reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if (LC_Type3==0|LC_Type3==3)&elec_use < 2000, vce(robust)  
 
reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if (LC_Type3==0|LC_Type3==4)&elec_use < 2000, vce(robust)  

reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if (LC_Type3==0|LC_Type3==5)&elec_use < 2000, vce(robust)  

**split summer / winter 
reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if summer==1 & elec_use < 2000, vce(robust)   
reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if summer==0 & elec_use < 2000, vce(robust)   
 
************************
*LC_Type4, 0 "Urban/Built up" 1 vege=("forest/shrubland/savanna" "grassland") "cropland" 4"water" 5"barren" 
************************
*gen LC_Type4=., after (LC_Type3)
** urban built up
*replace LC_Type4=0 if LC_Type3 ==0
** vege
*replace LC_Type4=1 if LC_Type3 == 1 | LC_Type3 == 3|LC_Type3 == 2
** water
*replace LC_Type4=4 if LC_Type3 ==4
** barren
*replace LC_Type4=5 if LC_Type3 ==5

reg elec_use DD_monthly  i.LC_Type4 c.DD_monthly#i.LC_Type4 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if elec_use < 2000, vce(robust)  

reg elec_use DD_monthly  i.LC_Type4 c.DD_monthly#i.LC_Type4 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if LC_Type4!= 5 & elec_use < 2000, vce(robust)

************************
*LC_Type5, 0 "Urban/Built up" 1 natural=("forest/shrubland/savanna" "grassland" "water") 3 "cropland" 5"barren" 
************************
*gen LC_Type5=., after (LC_Type3)
** urban built up
*replace LC_Type5=0 if LC_Type3 ==0
** natural
*replace LC_Type5=1 if LC_Type3 == 1 | LC_Type3 == 2|LC_Type3 == 4
** man made
*replace LC_Type5=3 if LC_Type3 ==3
** barren
*replace LC_Type5=5 if LC_Type3 ==5

reg elec_use DD_monthly  i.LC_Type5 c.DD_monthly#i.LC_Type5 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if elec_use < 2000, vce(robust)  

reg elec_use DD_monthly  i.LC_Type5 c.DD_monthly#i.LC_Type5 ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if LC_Type5!= 5 & elec_use < 2000, vce(robust)
 
************
**Tree_Cover 
************
histogram Tree_Cover if LC_Type3==0, saving ("/Users/JK/Dropbox/UHI/Tree_Cover0", replace)  
histogram Tree_Cover if LC_Type3==1, saving ("/Users/JK/Dropbox/UHI/Tree_Cover1", replace) 
histogram Tree_Cover if LC_Type3==2, saving ("/Users/JK/Dropbox/UHI/Tree_Cover2", replace)
histogram Tree_Cover if LC_Type3==3, saving ("/Users/JK/Dropbox/UHI/Tree_Cover3", replace) 
histogram Tree_Cover if LC_Type3==4, saving ("/Users/JK/Dropbox/UHI/Tree_Cover4", replace) 
histogram Tree_Cover if LC_Type3==5, saving ("/Users/JK/Dropbox/UHI/Tree_Cover5", replace)
* 
* as can see, tree cover is a good indicator for LC types  

**$$
reg elec_use DD_monthly  Tree_Cover c.DD_monthly#c.Tree_Cover ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if elec_use < 2000, vce(robust)  

reg elec_use DD_monthly  Tree_Cover c.DD_monthly#c.Tree_Cover ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if m_elec_use_tot <6 & elec_use < 2000, vce(robust)   
reg elec_use DD_monthly  Tree_Cover c.DD_monthly#c.Tree_Cover ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if m_elec_use_tot <7 & elec_use < 2000, vce(robust)   

reg elec_use DD_monthly  Tree_Cover c.DD_monthly#c.Tree_Cover ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if LC_Type3==0 & elec_use < 2000, vce(robust)  

 
**Both TC and LC_Type3
reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 Tree_Cover c.DD_monthly#c.Tree_Cover ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if elec_use < 2000, vce(robust)  
 
reg elec_use DD_monthly  i.LC_Type3 c.DD_monthly#i.LC_Type3 Tree_Cover c.DD_monthly#c.Tree_Cover ///
 fsize i.income i.urban i.b7 i.b13 i.b9 i.month i.province_n if m_elec_use_tot <6 & elec_use < 2000, vce(robust)

*****************************
**household fixed effects FE
*****************************
xtset ID
xtreg elec_use DD_monthly if elec_use < 2000, fe
*$$ LC_Type3
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if elec_use < 2000, fe
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if elec_use < 2000 & elec_use>0, fe
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if summer == 1 & elec_use < 2000, fe
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if summer == 0 & elec_use < 2000, fe
* b9 built year
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 c.DD_monthly#i.b9 if elec_use < 2000, fe
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 c.DD_monthly#i.b9 if summer == 1 & elec_use < 2000, fe
* window
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 c.DD_monthly#i.b18 if elec_use < 2000, fe
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 c.DD_monthly#i.b19 if elec_use < 2000, fe

*$$ urban
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 c.DD_monthly#i.urban if elec_use < 2000, fe

*$$ SF
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 c.DD_monthly#i.b2 if elec_use < 2000, fe
xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 c.DD_monthly#i.sf if elec_use < 2000, fe

*Tree_Cover
xtreg elec_use DD_monthly  c.DD_monthly#c.Tree_Cover if elec_use < 2000, fe
xtreg elec_use DD_monthly  c.DD_monthly#c.Tree_Cover if summer == 1 & elec_use < 2000, fe 
xtreg elec_use DD_monthly  c.DD_monthly#c.Tree_Cover if summer == 0 & elec_use < 2000, fe 
xtreg elec_use DD_monthly  c.DD_monthly#c.Tree_Cover c.DD_monthly#i.b9 if summer == 0 & elec_use < 2000, fe 

******************************** 
**Output
**table of summary statistics
estpost summarize elec_use fsize  DD_monthly NonVege, detail
esttab using Summary_statistics.tex , cells("mean sd count p10 p25 p50 p75 p90 p99 min max") label replace

**table of income
estpost tab income
esttab using Table_income.tex, cells("b pct(fmt(2)) cumpct(fmt(2))") replace noobs

**table of structure size
estpost tab b13
esttab using Table_size.tex, cells("b pct(fmt(2)) cumpct(fmt(2))") replace noobs

**table of built year
estpost tab  b9
esttab using Table_builtyear.tex, cells("b pct(fmt(2)) cumpct(fmt(2))") replace noobs

**table of ownership
estpost tab  b7
esttab using Table_own.tex, cells("b pct(fmt(2)) cumpct(fmt(2))") replace noobs

**table of urban
estpost tab  urban
esttab using Table_urban.tex, cells("b pct(fmt(2)) cumpct(fmt(2))") replace noobs

eststo clear

* baseline LC TC
eststo clear
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if elec_use < 2000, fe
*eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.Tree_Cover if elec_use < 2000, fe
eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.NonVege  if elec_use < 2000, fe  

esttab using Table_baseline.tex, label replace booktabs ///
   alignment(D{.}{.}{-1}) width(1\hsize)        ///
   title(Regression Table\label{tab:regbase})
   
* baseline LC TC DD_sq  
eststo clear 
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#i.LC_Type3 if elec_use < 2000, fe
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#c.Tree_Cover if elec_use < 2000, fe   

esttab using Table_baseline_sq.tex, label replace booktabs ///
   alignment(D{.}{.}{-1}) width(1\hsize)        ///
   title(With Degree Days Squared \label{tab:base_sq})

*summer
eststo clear
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if summer == 1 & elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.NonVege if summer == 1 & elec_use < 2000, fe 

esttab using Table_summer.tex, label replace booktabs ///
   alignment(D{.}{.}{-1}) width(1\hsize)        ///
   title( Summer\label{tab:summer})

*winter
eststo clear
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if summer == 0 & elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.NonVege if summer == 0 & elec_use < 2000, fe 

esttab using Table_winter.tex, label replace booktabs ///
   alignment(D{.}{.}{-1}) width(1\hsize)        ///
   title( Winter\label{tab:winter})      
   
*North China
eststo clear 
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if north==0 & elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.NonVege  if north==0 & elec_use < 2000, fe  

esttab using Table_North.tex, label replace booktabs ///
   alignment(D{.}{.}{-1}) width(1\hsize)        ///
   title( North China\label{tab:north})  
   
*eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if north==1 & elec_use < 2000, fe   
*eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if north==2 & elec_use < 2000, fe   
*South China
eststo clear
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if north!=0 & elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.NonVege  if north!=0 & elec_use < 2000, fe  
esttab using Table_South.tex, label replace booktabs ///
   alignment(D{.}{.}{-1}) width(1\hsize)        ///
   title( South China\label{tab:south})     
 


* SF urban
eststo clear
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.sf    c.DD_monthly#i.LC_Type3 if elec_use < 2000, fe
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.urban c.DD_monthly#i.LC_Type3 if elec_use < 2000, fe
 
esttab using Table_SF.tex, label replace booktabs ///
   alignment(D{.}{.}{-1}) width(1\hsize)        ///
   title(Single Family Home and Uran Home \label{tab:SF})   
tab sf urban   
   
* new building   
eststo clear
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.new c.DD_monthly#i.LC_Type3 if elec_use < 2000, fe
*eststo: xtreg elec_use DD_monthly  DD_sq c.DD_monthly#i.LC_Type4 c.DD_monthly#i.new if elec_use < 2000, fe
esttab using Table_Newly.tex, label replace booktabs ///
   alignment(D{.}{.}{-1}) width(1\hsize)        ///
   title(Built after 1990 \label{tab:newly})    

*******************
*summer winter DD_sq
eststo clear
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#i.LC_Type3 if summer == 1 & elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#i.LC_Type3 if summer == 0 & elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#c.Tree_Cover if summer == 1 & elec_use < 2000, fe 
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#c.Tree_Cover if summer == 0 & elec_use < 2000, fe 

esttab

   
* Non Vege Cover
eststo clear
eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.NonVege  if LC_Type3==0 & elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.NonVege  if elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#c.NonVege  if elec_use < 2000, fe 

*eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.Tree_Cover  if elec_use < 2000, fe  
*eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.Tree_Cover  if LC_Type3==0 & elec_use < 2000, fe   
*eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.NonTree_Vege  if elec_use < 2000, fe  
*eststo: xtreg elec_use DD_monthly  c.DD_monthly#c.NonTree_Vege  if LC_Type3==0 & elec_use < 2000, fe  


***Type4   
eststo clear
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if elec_use < 2000, fe
*with DD_sq
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#i.LC_Type3 if elec_use < 2000, fe

eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type4 if elec_use < 2000, fe  
*with DD_sq
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#i.LC_Type4 if elec_use < 2000, fe 

*summer
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if summer == 1 & elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type4 if summer == 1 & elec_use < 2000, fe 
*winter
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type3 if summer == 0 & elec_use < 2000, fe   
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type4 if summer == 0 & elec_use < 2000, fe 


esttab using Table_Type4.tex, label replace booktabs ///
     alignment(D{.}{.}{-1}) width(1.5\hsize)        ///
   title(Regression Table \label{tab:Type4})   
   
* Type6 (Type2') swith built-up and water so built-up is 0
gen LC_Type6=LC_Type2, after (LC_Type4)
* urban built up
replace LC_Type6=0  if LC_Type2 ==13
* water
replace LC_Type6=13 if LC_Type2 ==0
tab LC_Type6
   
eststo clear
eststo: xtreg elec_use DD_monthly  c.DD_monthly#i.LC_Type6 if elec_use < 2000, fe
eststo: xtreg elec_use DD_monthly DD_sq c.DD_monthly#i.LC_Type6 if elec_use < 2000, fe
 
 
save "/Users/JK/Dropbox/UHI/master.dta", replace

************************************
********* 8Day LST dataset *********
************************************
*8 day cycle, 68150 obs, 47 per ID
*(29 vars, 68150 obs)
import delimited "/Users/JK/Dropbox/UHI/lst2012_8day-terra/LST2012-8day-Terra-MOD11A2-006-results.csv", case(preserve) encoding(ISO-8859-1)clear
keep ID Date MOD11A2_006_LST_Day_1km MOD11A2_006_LST_Night_1km MOD11A2_006_QC_Day MOD11A2_006_QC_Night
rename MOD11A2_006_LST_Day_1km 		LST_Day_8
rename MOD11A2_006_LST_Night_1km 	LST_Night_8

*save "/Users/JK/Dropbox/UHI/lst2012_8day-terra/LST_8Day_terra.dta", replace

sort ID Date
* total number of rows with valid entry, same for the same ID
by ID: egen float D8_count_tot = total(LST_Day_8 != 0)
by ID: egen float N8_count_tot = total(LST_Night_8 != 0)
by ID: egen float Temp8_count_tot = total(LST_Day_8 != 0 & LST_Night_8 != 0)

* cumulative number of rows with valid entry
by ID: gen float D8_count = sum(LST_Day_8 != 0)
by ID: gen float N8_count = sum(LST_Night_8 != 0)
by ID: gen float Temp8_count = sum(LST_Day_8 != 0 & LST_Night_8 != 0)

* tag = 1 for the first instance of every ID, =0 otherwise
egen tag=tag(ID) 
codebook D8_count_tot if tag
codebook N8_count_tot if tag
codebook Temp8_count_tot if tag

save "/Users/JK/Dropbox/UHI/lst2012_8day-terra/LST_8Day_terra.dta", replace
*replace LST_Day_8 = . if (LST_Day_8==0)
*replace LST_Night_8 = . if (LST_Night_8==0)

************************************
************ LST dataset ***********
************************************

* daily, 530,700 obs, 366 per ID(leap year 2012)
* (31 vars, 530700 obs)
* 2 more than 8day data:MOD11A1_006_Clear_day_cov, MOD11A1_006_Clear_night_cov
* could explore later
import delimited "/Users/JK/Dropbox/UHI/lst2012/LST2012-MOD11A1-006-results.csv", case(preserve) encoding(ISO-8859-1)clear
keep ID Date MOD11A1_006_Clear_day_cov-MOD11A1_006_QC_Night /// 
	MODIS_Tile MOD11A1_006_Line_Y_1km MOD11A1_006_Sample_X_1km 
rename MOD11A1_006_LST_Day_1km 		LST_Day
rename MOD11A1_006_LST_Night_1km 	LST_Night
order LST_Day LST_Night, after (Date)
save "/Users/JK/Dropbox/UHI/lst2012/LST.dta", replace

sort ID Date
by ID: gen float D_count = sum(LST_Day != 0)
by ID: gen float N_count = sum(LST_Night != 0)
by ID: gen float Temp_count = sum(LST_Day != 0 & LST_Night != 0)

by ID: egen float D_count_tot = total(LST_Day != 0)
by ID: egen float N_count_tot = total(LST_Night != 0)
by ID: egen float Temp_count_tot = total(LST_Day != 0 & LST_Night != 0)
order D_count N_count Temp_count D_count_tot N_count_tot Temp_count_tot , after(LST_Night)

egen tag=tag(ID) 
tab tag
codebook D_count_tot if tag
codebook N_count_tot if tag
codebook Temp_count_tot if tag

* generate month 
gen month = substr(Date, 6, 2)
destring month, replace
* montly average
replace LST_Day = . if (LST_Day ==0)
replace LST_Night = . if (LST_Night ==0)
*bysort ID month: egen D_monthly = mean(LST_Day)
codebook LST_Day // missing  368,449/530,700 70%
codebook LST_Night //missing .:  337,983/530,700

save "/Users/JK/Dropbox/UHI/lst2012/LST.dta", replace



*merge

use "/Users/JK/Dropbox/UHI/lst2012/LST.dta", clear
merge 1:1 ID Date using "/Users/JK/Dropbox/UHI/lst2012_8day-terra/LST_8Day_terra.dta"
drop if _merge==2 //drop 2011-12-27
order LST_Day_8 LST_Night LST_Night_8 _merge, after (LST_Day)

gen date = date(Date, "YMD")
order date, after(Date)
format %tdCCYY-NN-DD date
xtset ID date

* combine  LST_Day and 8Day info
gen LST_Day_comb = .
order LST_Day_comb, after (LST_Day_8)
replace LST_Day_comb = LST_Day if (LST_Day != .)
*replace LST_Day_comb = l1.LST_Day_8 if LST_Day_comb == . & l1.LST_Day_8 != . & l1.LST_Day_8 !=0
replace LST_Day_comb = 	  LST_Day_8 if (LST_Day_comb == .)
replace LST_Day_comb = l1.LST_Day_8 if (LST_Day_comb == .)
replace LST_Day_comb = l2.LST_Day_8 if (LST_Day_comb == .)
replace LST_Day_comb = l3.LST_Day_8 if (LST_Day_comb == .)
replace LST_Day_comb = l4.LST_Day_8 if (LST_Day_comb == .)
replace LST_Day_comb = l5.LST_Day_8 if (LST_Day_comb == .)
replace LST_Day_comb = l6.LST_Day_8 if (LST_Day_comb == .)
replace LST_Day_comb = l7.LST_Day_8 if (LST_Day_comb == .)
replace LST_Day_comb = . if (LST_Day_comb == 0) //missing 98,168/530,700 18%

gen LST_Night_comb = ., after (LST_Night_8)

replace LST_Night_comb = LST_Night if (LST_Night != .)
replace LST_Night_comb =   	LST_Night_8 if (LST_Night_comb == .)
replace LST_Night_comb = l1.LST_Night_8 if (LST_Night_comb == .)
replace LST_Night_comb = l2.LST_Night_8 if (LST_Night_comb == .)
replace LST_Night_comb = l3.LST_Night_8 if (LST_Night_comb == .)
replace LST_Night_comb = l4.LST_Night_8 if (LST_Night_comb == .)
replace LST_Night_comb = l5.LST_Night_8 if (LST_Night_comb == .)
replace LST_Night_comb = l6.LST_Night_8 if (LST_Night_comb == .)
replace LST_Night_comb = l7.LST_Night_8 if (LST_Night_comb == .)
replace LST_Night_comb = . if (LST_Night_comb == 0)//70,508 to missing

*average Day and Night temperature
gen LST_comb_daily_avg = (LST_Day_comb+ LST_Night_comb)/2,after(LST_Night_comb)//128,144 missing, 24%
order month, after (LST_comb_daily_avg)
sort ID month
* goodday_count count the number of days with LST reading within a month
by ID month: egen goodday_count= count(LST_comb_daily_avg)
* looking at month with high missing LSTs
* doesnt' seem like any partular month is missing too much, jan feb jun
tab goodday_count month if goodday_count<11 //total  59,262

**** LST_mthly_avg ****
bysort ID month: egen LST_mthly_avg= mean(LST_comb_daily_avg)
order LST_mthly_avg, after(LST_comb_daily_avg)
* order D_monthly, after(LST_comb_daily_avg)
*save "/Users/JK/Dropbox/UHI/lst2012/LST_m.dta", replace

* convert from Kelvin to Celsius
replace LST_mthly_avg = LST_mthly_avg - 273.15

*** HDD, CDD***
gen HDD = max(18-LST_mthly_avg,0) if LST_mthly_avg!= . ,after(LST_mthly_avg)
gen CDD = max(LST_mthly_avg-18,0) if LST_mthly_avg!= . ,after(LST_mthly_avg)

gen DD  = HDD + CDD, after(HDD)
***sum over month, if all missing, then treat as missing
by ID month: egen  DD_monthly = total(DD) , missing
order DD DD_monthly, after (HDD)

save "/Users/JK/Dropbox/UHI/lst2012/LST_merge.dta", replace

duplicates drop ID month, force
graph box CDD HDD, over(month) legend(on)
graph export "/Users/JK/Dropbox/UHI/CDD_HDD_m.eps", as(eps) preview(off)
graph save Graph "/Users/JK/Dropbox/UHI/CDD_HDD_m.gph"

graph box HDD, over(month) legend(on)
graph export "/Users/JK/Dropbox/UHI/HDD.eps", as(eps) preview(off)
graph save Graph "/Users/JK/Dropbox/UHI/HDD.gph"

graph box CDD, over(month) legend(on)
graph export "/Users/JK/Dropbox/UHI/CDD.eps", as(eps) preview(off)
graph save Graph "/Users/JK/Dropbox/UHI/CDD.gph"

keep ID month DD_monthly goodday_count
save "/Users/JK/Dropbox/UHI/lst2012/LST_pre.dta", replace

* keep ID Date date month DD_monthly goodday_count

************************************
* Land Cover type dataset, annually
************************************
import delimited "/Users/JK/Dropbox/UHI/landcover2012/LandCover2012-MCD12Q1-006-results.csv", case(preserve)clear
rename MCD12Q1_006_LC_Type1 LC_Type1
rename MCD12Q1_006_LC_Type2 LC_Type2
order Date LC_Type1 LC_Type2, after (ID)
sort ID
save "/Users/JK/Dropbox/UHI/landcover2012/LC.dta", replace
keep ID LC_Type1 LC_Type2
save "/Users/JK/Dropbox/UHI/landcover2012/LC_pre.dta", replace

************************************
**** VCF dataset, annually
************************************
import delimited "/Users/JK/Dropbox/UHI/vegetation-continuous-fields-2012/Vegetation-Continuous-Fields-2012-MOD44B-006-results.csv", case(preserve) encoding(ISO-8859-1)clear
keep ID Date MOD44B_006_Line_Y_250m MOD44B_006_Sample_X_250m ///
MOD44B_006_Percent_NonVegetated MOD44B_006_Percent_Tree_Cover MOD44B_006_Percent_NonTree_Veget
rename MOD44B_006_Percent_Tree_Cover 	Tree_Cover
rename MOD44B_006_Percent_NonTree_Veget	 NonTree_Vege
rename MOD44B_006_Percent_NonVegetated	 NonVege
sort ID
replace Tree_Cover=. if Tree_Cover>100
replace NonTree_Vege=. if NonTree_Vege>100
replace NonVege=. if NonVege>100
* check if sum up to 100, yes
gen tot = Tree_Cover + NonTree_Vege + NonVege
tab tot
drop tot
save "/Users/JK/Dropbox/UHI/vegetation-continuous-fields-2012/VGF.dta",replace
keep ID Tree_Cover NonTree_Vege NonVege
save "/Users/JK/Dropbox/UHI/vegetation-continuous-fields-2012/VGF_pre.dta",replace
* have missing value .

************************************
**** Evapotranspiration, 8Day ******
************************************
import delimited "/Users/JK/Dropbox/UHI/evapotranspiration-2012/Evapotranspiration-2012-MOD16A2-006-results.csv", case(preserve) encoding(ISO-8859-1)clear
sum MOD16A2_006_ET_500m if MOD16A2_006_ET_500m <32761, detail
tab MOD16A2_006_ET_500m if MOD16A2_006_ET_500m >= 32761

/*
32767 = _Fillvalue
32766 = land cover assigned as perennial salt or Water bodies
32765 = land cover assigned as barren,sparse veg (rock,tundra,desert) (A2/A2GF), also used
		for data gaps from cloud cover and snow for vegetated pixels (A2)
32764 = land cover assigned as perennial snow,ice.
32763 = land cover assigned as "permanent" wetlands/inundated marshland 
32762 = land cover assigned as urban/built-up
32761 = land cover assigned as "unclassified" or (not able to determine)*/

keep ID Date MOD16A2_006_ET_500m
save "/Users/JK/Dropbox/UHI/evapotranspiration-2012/ET.dta",replace

* 集中供暖情况
tab d1
tab province d1
tab d2g d1,missing
tab d2a d1,missing

tab d3_1a d1,missing
* 有二十户 d1 missing 的 其实可以label为 分户自供
*drop if d1!=4
*tab d3_1a
* 只有一家列了没有供暖 但是后面列了供暖设备
tab d3_1a d3_1b
* 自供暖的家庭，除了用电，主要是烧柴或煤炭，大概是2：1的比例，但是煤炭消费量的missing
* 太多了

* 目前的思路
* 如果只看电力消费的话， UHI应该在冬季不影响 集中供暖和没有供暖的家庭
* 对分户自供的家庭，应该只对(主要使用电为燃料）的家庭（约占2/3）有影响，在夏季应该都有影响
* 如果看天然气，薪柴木炭这类消费的话（f6_2,4,6,7), UHI 应该在冬季对分户自供的家庭中（主要
* 使用这类燃料的）家庭有影响，在夏季反而应该都没有影响

* 万一UHI的variation太小 看不出effect？或者有confounding variable

*看一下整年的电力消费量和支出金额

codebook f3_13_a
codebook f3_13_d
* 基本上missing的obs集中在吉林 可能有办法找回

histogram f3_13_a, kdensity
histogram  f3_13_d, kdensity
histogram f3_13_a, kdensity addplot((histogram f3_13_d, yaxis(2)))
twoway (scatter f3_13_a f3_13_d, sort)
. twoway (scatter f3_13_a f3_13_d)
