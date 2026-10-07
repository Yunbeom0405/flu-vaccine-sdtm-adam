/*******************************************************************************
Program : setup.sas
Purpose : Paths and shared macros for the TLF programs
*******************************************************************************/

%let root = U:\My SAS Files\Portfolio3;
%let out = &root/output/tlf/sas;

options validvarname=upcase dlcreatedir nodate nonumber orientation=landscape;
libname adam "&root/data/derived/adam" access=readonly;
libname _out "&out";
libname _out clear;

/* treatment columns: 1 VAXF-101, 2 Placebo, 3 Total */
proc format;
value $trtcol
  'VAXF-101 0.5 mL' = '1'
  'Placebo' = '2';
run;

/* fixed decimals, half away from zero */
%macro f(x, d);
ifc(missing(&x), '', strip(put(round(coalesce(&x, 0), 10 ** -&d), 32.&d)))
%mend f;

/* n (pct%) with pct at &d decimals; plain 0 when n = 0 */
%macro npct(n, den, d=0);
ifc(&n = 0, '0', cats(&n) || ' (' || %f(&n / &den * 100, &d) || '%)')
%mend npct;

/* Clopper-Pearson 95% limits in percent: needs x and n, returns text in &out */
%macro cp(x, n, out);
if &x = 0 then _lo = 0; else _lo = betainv(0.025, &x, &n - &x + 1);
if &x = &n then _up = 1; else _up = betainv(0.975, &x + 1, &n - &x);
&out = cat(%f(_lo * 100, 1), '; ', %f(_up * 100, 1));
%mend cp;

/* column N from ADSL into &n1 - &n3 (3 = all arms); &flag selects the population */
%macro bign(trt, flag);
  %global n1 n2 n3;
  proc sql noprint;
    select count(*) into :n1 trimmed from adam.adsl where &flag = 'Y' and &trt = 'VAXF-101 0.5 mL';
    select count(*) into :n2 trimmed from adam.adsl where &flag = 'Y' and &trt = 'Placebo';
    select count(*) into :n3 trimmed from adam.adsl where &flag = 'Y';
  quit;
%mend bign;

/* row builders: long dataset of col, row, indent, label, val; &ncol columns */
%macro start(ncol);
  %global rw nc;
  %let rw = 0;
  %let nc = &ncol;
  data long;
    length col row indent 8 label $200 val $40;
    stop;
  run;
%mend start;

/* header row, no values */
%macro hdr(indent, label);
  %let rw = %eval(&rw + 1);
  data _l;
    length label $200 val $40;
    do col = 1 to &nc;
      row = &rw; indent = &indent; label = "&label"; val = '';
      output;
    end;
  run;
  proc append base=long data=_l force;
  run;
%mend hdr;

/* count row: subjects meeting &cond in dataset POP, with pct of the column N */
%macro line(indent, label, cond, d=0);
  %let rw = %eval(&rw + 1);
  proc sql;
    create table _l as
    select col, sum((&cond)) as n from pop group by col;
  quit;
  data _l;
    set _l;
    length label $200 val $40;
    row = &rw; indent = &indent; label = "&label";
    val = %npct(n, choosen(col, &n1, &n2, &n3), d=&d);
    keep col row indent label val;
  run;
  proc append base=long data=_l force;
  run;
%mend line;

/* text row from a dataset VAL by col: use after building _l yourself */
%macro addrow(indent, label);
  %let rw = %eval(&rw + 1);
  data _l;
    length label $200 val $40;
    set _l;
    row = &rw; indent = &indent; label = "&label";
    keep col row indent label val;
  run;
  proc append base=long data=_l force;
  run;
%mend addrow;

/* long -> wide display dataset c1-c&nc */
%macro wide(out);
  proc sort data=long;
    by row label indent col;
  run;
  proc transpose data=long out=&out(drop=_name_) prefix=c;
    by row label indent;
    id col;
    var val;
  run;
%mend wide;

/* display dataset (ROW LABEL INDENT C1-Cn) -> RTF + CSV for QC */
%macro report(ds, file, title, cols=, heads=, foot1=, foot2=);
  %local i n;
  %let n = %sysfunc(countw(&cols));

  ods listing close;
  ods rtf file="&out/&file..rtf" style=journal bodytitle;
  title1 j=l 'Protocol: VAXF101 (synthetic data)' j=r 'Page ^{thispage} of ^{lastpage}';
  title2 "&title";
  footnote1 j=l "&foot1";
  footnote2 j=l "&foot2";
  footnote3 j=l "Source: sas/tlf/&file..sas";
  ods escapechar='^';

  proc report data=&ds nowd split='|' style(report)={width=100%};
    column row indent label &cols;
    define row / order noprint;
    define indent / display noprint;
    define label / display ' ' style(column)={width=45%};
    %do i = 1 %to &n;
      define %scan(&cols, &i) / display "%scan(&heads, &i, #)" style(column)={just=c};
    %end;
    compute label;
      if indent > 0 then call define(_col_, 'style', cats('style={leftmargin=', indent * 12, 'pt}'));
    endcomp;
  run;

  ods rtf close;
  ods listing;
  title;
  footnote;

  proc export data=&ds(keep=row label &cols) outfile="&out/&file..csv" dbms=csv replace;
  run;
%mend report;
