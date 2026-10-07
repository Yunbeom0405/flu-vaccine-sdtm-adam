/*******************************************************************************
Program : setup.sas
Purpose : Paths, raw data import and shared macros for the SDTM programs
*******************************************************************************/

%let root = U:\My SAS Files\Portfolio3;
%let raw  = &root/data/raw;
%let xpt  = &root/data/derived/sdtm;

options validvarname=upcase dlcreatedir compress=yes;
libname sdtm "&xpt";

/* read csv as all character, variable names from the header row */
%macro readcsv(file);
  %local vars;
  data _null_;
    infile "&raw/&file..csv" obs=1 lrecl=32767 termstr=lf;
    input;
    call symputx('vars', translate(compress(_infile_, '"' || '0D'x), ' ', ','));
  run;

  data raw_&file;
    infile "&raw/&file..csv" dsd firstobs=2 truncover lrecl=32767 termstr=lf;
    input @;
    _infile_ = compress(_infile_, '0D'x);
    length &vars $200;
    input &vars;
  run;
%mend readcsv;

%readcsv(ic)
%readcsv(dm)
%readcsv(ie)
%readcsv(rand)
%readcsv(visit)
%readcsv(vitals)
%readcsv(ex)
%readcsv(obs30)
%readcsv(diary)
%readcsv(ae)
%readcsv(ds)
%readcsv(lb_hai)

proc format;
invalue visitn (upcase)
'SCREENING' = 1
'DAY 1' = 2
'DAY 8' = 3
'DAY 22' = 4
'DAY 91' = 5;
value $armcd
'A' = 'VAXF'
'B' = 'PBO';
value $arm
'A' = 'VAXF-101 0.5 mL'
'B' = 'Placebo';
run;

/* DD-MON-YYYY -> ISO 8601, unknown day dropped (UN-MAR-2025 -> 2025-03) */
%macro iso(in, out);
  if substr(&in, 1, 2) = 'UN' then
    &out = put(input(cats('01', substr(&in, 4, 3), substr(&in, 8, 4)), date9.), yymmd7.);
  else if not missing(&in) then &out = put(input(compress(&in, '-'), date9.), e8601da.);
%mend iso;

/* date and time collected separately */
%macro isodt(d, t, out);
  %iso(&d, &out)
  if not missing(&t) and not missing(&out) then &out = catx('T', &out, &t);
%mend isodt;

/* study day, complete dates only; needs rfstdtc on the record */
%macro dy(dtc, out);
&out = .;
if length(&dtc) >= 10 and length(rfstdtc) >= 10 then do;
  &out = input(substr(&dtc, 1, 10), e8601da.) - input(substr(rfstdtc, 1, 10), e8601da.);
  &out = &out + (&out >= 0);
end;
%mend dy;

/* epoch from the dose date; partial dates stay null */
%macro epoch(dtc);
if length(&dtc) >= 10 then do;
  if missing(rfxstdtc) or substr(&dtc, 1, 10) < substr(rfxstdtc, 1, 10) then epoch = 'SCREENING';
  else if substr(&dtc, 1, 10) <= substr(rfxendtc, 1, 10) then epoch = 'TREATMENT';
  else epoch = 'FOLLOW-UP';
end;
%mend epoch;

/* pre-dose: screening or Day 1 sample of a dosed subject */
%macro predose;
_pre = (visitnum in (1, 2) and not missing(rfxstdtc));
%mend predose;

/* pre-dose records are SCREENING, also on the dose date */
%macro fepoch(dtc);
if _pre and length(&dtc) >= 10 then epoch = 'SCREENING';
else %epoch(&dtc)
%mend fepoch;

/* flag last pre-dose record with a result, per subject and &by */
%macro lobxfl(in, flag, by=, res=, dtc=);
  proc sort data=&in(where=(_pre and not missing(&res))) out=_lobx(keep=_row usubjid &by &dtc visitnum);
    by usubjid &by &dtc visitnum;
  run;

  data _lobx;
    set _lobx;
    by usubjid &by;
    if last.%scan(&by, -1);
    keep _row;
  run;

  proc sort data=_lobx;
    by _row;
  run;

  proc sort data=&in;
    by _row;
  run;

  data &in;
    merge &in _lobx(in=_hit);
    by _row;
    length &flag $1;
    if _hit then &flag = 'Y';
  run;
%mend lobxfl;

%include "&root/sas/macros/finalize.sas";
