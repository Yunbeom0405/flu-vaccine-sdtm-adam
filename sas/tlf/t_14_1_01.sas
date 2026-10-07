/*******************************************************************************
Program : t_14_1_01.sas
Purpose : Table 14-1.01 Summary of Populations, Disposition and Demographics
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\tlf\setup.sas";

%bign(trt01p, randfl)

data pop;
  set adam.adsl(where=(randfl = 'Y'));
  col = input(put(trt01p, $trtcol.), 1.);
  output;
  col = 3;
  output;
run;

%start(3)

%line(0, Randomized, %str(randfl = 'Y'))
%line(0, Dosed (safety population), %str(saffl = 'Y'))
%line(0, Immunogenicity per-protocol population, %str(immfl = 'Y'))
%line(0, Completed study, %str(eosstt = 'COMPLETED'))
%line(0, Discontinued study, %str(eosstt = 'DISCONTINUED'))
%line(1, Lost to follow-up, %str(dcsreas = 'LOST TO FOLLOW-UP'))
%line(1, Withdrawal by subject, %str(dcsreas = 'WITHDRAWAL BY SUBJECT'))

%hdr(0, Age (years))
proc sql;
  create table _l as
  select col, strip(put(count(age), 8.)) as val from pop group by col;
quit;
%addrow(1, n)
proc sql;
  create table _l as
  select col, cat(%f(mean(age), 1), ' (', %f(std(age), 2), ')') as val from pop group by col;
quit;
%addrow(1, Mean (SD))
proc means data=pop noprint nway;
  class col;
  var age;
  output out=_m median=med min=mn max=mx;
run;
data _l;
  set _m;
  length val $40;
  val = %f(med, 1);
run;
%addrow(1, Median)
data _l;
  set _m;
  length val $40;
  val = cat(%f(mn, 0), '; ', %f(mx, 0));
run;
%addrow(1, Min; Max)

%hdr(0, Age group)
%line(1, 18-45, %str(agegr1 = '18-45'))
%line(1, 46-60, %str(agegr1 = '46-60'))
%hdr(0, Sex)
%line(1, Female, %str(sex = 'F'))
%line(1, Male, %str(sex = 'M'))
%hdr(0, Race)
%line(1, Asian, %str(race = 'ASIAN'))
%line(1, Black or African American, %str(race = 'BLACK OR AFRICAN AMERICAN'))
%line(1, White, %str(race = 'WHITE'))
%line(1, Other, %str(race = 'OTHER'))
%hdr(0, Ethnicity)
%line(1, Hispanic or Latino, %str(ethnic = 'HISPANIC OR LATINO'))
%line(1, Not Hispanic or Latino, %str(ethnic = 'NOT HISPANIC OR LATINO'))

%wide(t_14_1_01)

%report(t_14_1_01, t_14_1_01, Table 14-1.01 Summary of Populations%str(,) Disposition and Demographics,
  cols=c1 c2 c3,
  heads=VAXF-101 0.5 mL|(N=&n1)#Placebo|(N=&n2)#Total|(N=&n3),
  foot1=Population: randomized. Percentages use N in the column header%str(;) arms are as randomized.,
  foot2=27 screen failures are not in this table. Synthetic data.)
