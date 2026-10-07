/*******************************************************************************
Program : setup.sas
Purpose : Paths and shared macros for the ADaM programs
*******************************************************************************/

%let root = U:\My SAS Files\Portfolio3;
%let xpt = &root/data/derived/adam;

options validvarname=upcase dlcreatedir compress=yes;
libname sdtm "&root/data/derived/sdtm" access=readonly;
libname adam "&xpt";

%include "&root/sas/macros/finalize.sas";

/* ISO 8601 date text -> SAS date, date part only */
%macro dt(dtc, out);
if length(&dtc) >= 10 then &out = input(substr(&dtc, 1, 10), e8601da.);
format &out date9.;
%mend dt;

/* analysis day relative to first dose, no day 0 */
%macro ady(dt, out);
if &dt ne . and trtsdt ne . then &out = &dt - trtsdt + (&dt >= trtsdt);
%mend ady;

/* ADSL variables onto analysis records */
%macro addadsl(in, out, vars);
proc sort data=&in out=_add;
  by usubjid;
run;

data &out;
  merge _add(in=_in) adam.adsl(keep=usubjid &vars);
  by usubjid;
  if _in;
run;
%mend addadsl;
