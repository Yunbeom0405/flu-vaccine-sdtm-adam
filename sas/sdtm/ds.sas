/*******************************************************************************
Program : ds.sas
Purpose : Create SDTM DS
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

data ds0;
  length usubjid dscat dsdecod dsrefid dsstdtc $200;
  set raw_ic(in=a keep=subject icdat rename=(icdat=dat))
    raw_rand(in=b keep=subject randdat randnum rename=(randdat=dat))
    raw_ds(in=c keep=subject dsdat dsterm rename=(dsdat=dat));

  usubjid = cats('VAXF101-', subject);
  if a then do;
    ord = 1;
    dscat = 'PROTOCOL MILESTONE';
    dsterm = 'INFORMED CONSENT OBTAINED';
  end;
  else if b then do;
    ord = 2;
    dscat = 'PROTOCOL MILESTONE';
    dsterm = 'RANDOMIZED';
    dsrefid = randnum;
  end;
  else do;
    ord = 3;
    dscat = 'DISPOSITION EVENT';
    dsterm = upcase(dsterm);
  end;
  dsdecod = dsterm;
  %iso(dat, dsstdtc)
run;

proc sql;
  create table ds1 as
  select a.*, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from ds0 a left join sdtm.dm d on a.usubjid = d.usubjid
  order by a.usubjid, a.dsstdtc, a.ord;
quit;

data ds2;
  length studyid domain epoch $200;
  set ds1;
  by usubjid;
  studyid = 'VAXF101';
  domain = 'DS';
  if first.usubjid then dsseq = 0;
  dsseq + 1;
  %epoch(dsstdtc)
  if dscat = 'PROTOCOL MILESTONE' then epoch = 'SCREENING';
  %dy(dsstdtc, dsstdy)
  label
    studyid = 'Study Identifier'
    domain  = 'Domain Abbreviation'
    usubjid = 'Unique Subject Identifier'
    dsseq   = 'Sequence Number'
    dsrefid = 'Reference ID'
    dsterm  = 'Reported Term for the Disposition Event'
    dsdecod = 'Standardized Disposition Term'
    dscat   = 'Category for Disposition Event'
    epoch   = 'Epoch'
    dsstdtc = 'Start Date/Time of Disposition Event'
    dsstdy  = 'Study Day of Start of Disposition Event';
run;

%finalize(ds2, ds, Disposition,
  vars=STUDYID DOMAIN USUBJID DSSEQ DSREFID DSTERM DSDECOD DSCAT EPOCH DSSTDTC DSSTDY,
  keys=STUDYID USUBJID DSDECOD DSSTDTC)
