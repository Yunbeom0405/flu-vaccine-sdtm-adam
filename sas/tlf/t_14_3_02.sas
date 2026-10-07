/*******************************************************************************
Program : t_14_3_02.sas
Purpose : Table 14-3.02 Unsolicited Adverse Events through Day 22 and Serious Adverse Events through Day 91
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\tlf\setup.sas";

%bign(trt01a, saffl)

data pop;
  set adam.adae(where=(saffl = 'Y'));
  col = input(put(trt01a, $trtcol.), 1.);
run;

data cols;
  do col = 1 to 2;
    output;
  end;
run;

data aelong;
  length sec socrank ptrank col indent 8 label $200 val $40;
  stop;
run;

/* one section: any, then SOC / PT by descending total subjects, ties alphabetical */
%macro section(sec, flag, anylabel, bysoc);
  proc sql;
    create table g as select distinct aebodsys, aedecod from pop where &flag = 'Y';
    create table gc as select g.aebodsys, g.aedecod, c.col from g, cols c;
    create table n1 as
      select col, aebodsys, aedecod, count(distinct usubjid) as n
      from pop where &flag = 'Y' group by col, aebodsys, aedecod;
    create table pt as
      select a.col, a.aebodsys, a.aedecod, coalesce(b.n, 0) as n
      from gc a left join n1 b on a.col = b.col and a.aebodsys = b.aebodsys and a.aedecod = b.aedecod;
    create table n2 as
      select col, aebodsys, count(distinct usubjid) as n
      from pop where &flag = 'Y' group by col, aebodsys;
    create table socc as
      select a.col, a.aebodsys, coalesce(b.n, 0) as n
      from (select distinct aebodsys, col from gc) a left join n2 b on a.col = b.col and a.aebodsys = b.aebodsys;
    create table ptt as select aebodsys, aedecod, sum(n) as tot from pt group by aebodsys, aedecod;
    create table soct as select aebodsys, sum(n) as tot from socc group by aebodsys;
    create table anyn as
      select c.col, coalesce(b.n, 0) as n
      from cols c left join
        (select col, count(distinct usubjid) as n from pop where &flag = 'Y' group by col) b on c.col = b.col;
  quit;

  %if &bysoc = 1 %then %do;
    proc sort data=soct;
      by descending tot aebodsys;
    run;
    data soct;
      set soct;
      socrank = _n_;
    run;
    proc sort data=ptt;
      by aebodsys descending tot aedecod;
    run;
    data ptt;
      set ptt;
      by aebodsys;
      if first.aebodsys then ptrank = 0;
      ptrank + 1;
    run;
  %end;
  %else %do;
    data soct;
      set soct;
      socrank = 0;
    run;
    proc sort data=ptt;
      by descending tot aedecod;
    run;
    data ptt;
      set ptt;
      ptrank = _n_;
    run;
  %end;

  data _x;
    set anyn;
    length label $200 val $40;
    sec = &sec; socrank = -1; ptrank = 0; indent = 0; label = "&anylabel";
    val = %npct(n, choosen(col, &n1, &n2), d=1);
    keep sec socrank ptrank col indent label val;
  run;
  proc append base=aelong data=_x force;
  run;

  %if &bysoc = 1 %then %do;
    proc sql;
      create table _x as
      select &sec as sec, b.socrank, 0 as ptrank, a.col, 1 as indent, a.aebodsys as label length=200, a.n
      from socc a, soct b where a.aebodsys = b.aebodsys;
    quit;
    data _x;
      set _x;
      length val $40;
      val = %npct(n, choosen(col, &n1, &n2), d=1);
      keep sec socrank ptrank col indent label val;
    run;
    proc append base=aelong data=_x force;
    run;
  %end;

  proc sql;
    create table _x as
    select &sec as sec, c.socrank, b.ptrank, a.col, %eval(1 + &bysoc) as indent, a.aedecod as label length=200, a.n
    from pt a, ptt b, soct c
    where a.aebodsys = b.aebodsys and a.aedecod = b.aedecod and a.aebodsys = c.aebodsys;
  quit;
  data _x;
    set _x;
    length val $40;
    val = %npct(n, choosen(col, &n1, &n2), d=1);
    keep sec socrank ptrank col indent label val;
  run;
  proc append base=aelong data=_x force;
  run;
%mend section;

%section(1, anl01fl, Any unsolicited AE through Day 22, 1)
%section(2, anl02fl, Any serious AE through Day 91, 0)

proc sort data=aelong;
  by sec socrank ptrank col;
run;

data long;
  set aelong;
  by sec socrank ptrank;
  if first.ptrank then row + 1;
  keep col row indent label val;
run;

%wide(t_14_3_02)

%report(t_14_3_02, t_14_3_02, Table 14-3.02 Adverse Events (Unsolicited through Day 22%str(,) Serious through Day 91),
  cols=c1 c2,
  heads=VAXF-101 0.5 mL|(N=&n1)#Placebo|(N=&n2),
  foot1=Population: safety%str(,) arms as treated. Subjects counted once per term. Treatment-emergent events only.,
  foot2=No MedDRA: system organ class and preferred term come from a local coding table.)
