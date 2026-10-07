/*******************************************************************************
Program : t_14_2_01.sas
Purpose : Table 14-2.01 HAI Immunogenicity: GMT, GMFR, Seroprotection, Seroconversion
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\tlf\setup.sas";

%bign(trt01p, immfl)

data pop;
  set adam.adis(where=(anl01fl = 'Y'));
  col = input(put(trt01p, $trtcol.), 1.);
  lnaval = log(aval);
  lnr = log(r2base);
run;

proc sql;
  create table st as
  select col, paramn, avisitn,
    count(aval) as n, mean(lnaval) as m, std(lnaval) as s,
    count(r2base) as nr, mean(lnr) as mr, std(lnr) as sr,
    sum(crit1fl = 'Y') as sp, count(crit1fl) as nsp,
    sum(crit2fl = 'Y') as sc, count(crit2fl) as nsc
  from pop
  group by col, paramn, avisitn;
quit;

/* GMT / GMFR: mean of ln(value), t-based 95% CI, back-transformed */
%macro gm(m, s, n, out);
_t = tinv(0.975, &n - 1);
&out = cat(%f(exp(&m), 1), ' (', %f(exp(&m - _t * &s / sqrt(&n)), 1), '; ',
  %f(exp(&m + _t * &s / sqrt(&n)), 1), ')');
%mend gm;

data long;
  set st;
  length label $200 val $40;
  b = (paramn - 1) * 14;
  if avisitn = 2 then do;
    row = b + 3; indent = 2; label = 'n'; val = strip(put(n, 8.)); output;
    row = b + 4; indent = 2; label = 'GMT (95% CI)'; %gm(m, s, n, val) output;
    row = b + 5; indent = 2; label = 'Seroprotection (titer >= 40), n'; val = %npct(sp, nsp, d=1); output;
    row = b + 6; indent = 3; label = '95% CI'; %cp(sp, nsp, val) output;
  end;
  else do;
    row = b + 8; indent = 2; label = 'n'; val = strip(put(n, 8.)); output;
    row = b + 9; indent = 2; label = 'GMT (95% CI)'; %gm(m, s, n, val) output;
    row = b + 10; indent = 2; label = 'GMFR, Day 22 / Day 1 (95% CI)'; %gm(mr, sr, nr, val) output;
    row = b + 11; indent = 2; label = 'Seroprotection (titer >= 40), n'; val = %npct(sp, nsp, d=1); output;
    row = b + 12; indent = 3; label = '95% CI'; %cp(sp, nsp, val) output;
    row = b + 13; indent = 2; label = 'Seroconversion, n'; val = %npct(sc, nsc, d=1); output;
    row = b + 14; indent = 3; label = '95% CI'; %cp(sc, nsc, val) output;
  end;
  keep col row indent label val;
run;

/* header rows */
data hdrs;
  length label $200 val $40;
  do p = 1 to 3;
    b = (p - 1) * 14;
    do col = 1 to 2;
      val = '';
      row = b + 1; indent = 0; label = cat('HAI titer, Strain ', byte(64 + p)); output;
      row = b + 2; indent = 1; label = 'Day 1'; output;
      row = b + 7; indent = 1; label = 'Day 22'; output;
    end;
  end;
  keep col row indent label val;
run;

data long;
  set long hdrs;
run;

%wide(t_14_2_01)

%report(t_14_2_01, t_14_2_01, Table 14-2.01 HAI Immunogenicity by Strain,
  cols=c1 c2,
  heads=VAXF-101 0.5 mL|(N=&n1)#Placebo|(N=&n2),
  foot1=Population: immunogenicity per-protocol. Titers below the LLOQ (10) are set to 5 for GMT and GMFR.,
  foot2=Seroconversion: baseline < 10 and Day 22 >= 40%str(,) or baseline >= 10 and 4-fold rise. 95% CI: t on ln(titer) for GMT/GMFR%str(,) Clopper-Pearson for percentages.)
