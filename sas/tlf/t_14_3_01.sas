/*******************************************************************************
Program : t_14_3_01.sas
Purpose : Table 14-3.01 Solicited Local and Systemic Reactions by Maximum Grade
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\tlf\setup.sas";

%bign(trt01a, saffl)

data pop;
  set adam.adce(where=(saffl = 'Y'));
  col = input(put(trt01a, $trtcol.), 1.);
run;

%start(2)

%macro react(wn, wlabel);
  %local i s g r lab sc;
  %hdr(0, &wlabel)
  %do s = 1 %to 2;
    %let sc = %scan(LOCAL SYSTEMIC, &s);
    %let lab = %sysfunc(lowcase(&sc));
    %line(1, Any &lab reaction, %str(atptn = &wn and aoccsfl = 'Y' and cescat = "&sc"), d=1)
    %do g = 1 %to 4;
      %line(2, Maximum grade &g, %str(atptn = &wn and aoccsfl = 'Y' and cescat = "&sc" and atoxgrn = &g), d=1)
    %end;
  %end;
  %do i = 1 %to 13;
    %let r = %scan(PAIN TENDERNESS REDNESS SWELLING INDURATION FEVER CHILLS MALAISE MYALGIA HEADACHE ARTHRALGIA NAUSEA VOMITING, &i);
    %let lab = %sysfunc(propcase(&r));
    %line(1, &lab, %str(atptn = &wn and cedecod = "&r" and atoxgrn >= 1), d=1)
    %line(2, Grade 2 or higher, %str(atptn = &wn and cedecod = "&r" and atoxgrn >= 2), d=1)
  %end;
%mend react;

%react(0, Within 30 minutes after vaccination)
%react(8, Within 7 days after vaccination)

%wide(t_14_3_01)

%report(t_14_3_01, t_14_3_01, Table 14-3.01 Solicited Local and Systemic Reactions by Maximum Grade,
  cols=c1 c2,
  heads=VAXF-101 0.5 mL|(N=&n1)#Placebo|(N=&n2),
  foot1=Population: safety (randomized and dosed)%str(,) arms as treated. Subjects counted once per reaction at the maximum grade.,
  foot2=FDA 2007 toxicity grading scale for preventive vaccine trials. Diameters under 25 mm are not reactions.)
