/*******************************************************************************
Program : adsl.sas
Purpose : Create ADaM ADSL
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\adam\setup.sas";

proc format;
invalue trtn
'VAXF-101 0.5 mL' = 1
'Placebo' = 2;
run;

proc sql;
  create table rand as
  select usubjid, dsstdtc as randdtc from sdtm.ds where dsdecod = 'RANDOMIZED';

  create table eos as
  select usubjid, dsdecod as eosdecod, dsstdtc as eosdtc
  from sdtm.ds where dscat = 'DISPOSITION EVENT';

  /* valid result at both visits for all three strains, Day 22 sample in window */
  create table imm as
  select usubjid, 'Y' as immok length=1
  from sdtm.is
  where isstat = '' and isstresc ne '' and (visitnum = 2 or (visitnum = 4 and 19 <= isdy <= 25))
  group by usubjid
  having count(*) = 6;
quit;

data adsl0;
  merge sdtm.dm(in=_dm) rand eos imm;
  by usubjid;
  if _dm;
run;

data adsl1;
  set adsl0;
  length agegr1 $5 trt01p trt01a $40 eosstt $12 dcsreas $40 randfl saffl immfl $1;
  trt01p = arm;
  trt01a = actarm;
  if trt01p ne '' then trt01pn = input(trt01p, trtn.);
  if trt01a ne '' then trt01an = input(trt01a, trtn.);
  if age ne . then do;
    agegr1 = ifc(age <= 45, '18-45', '46-60');
    agegr1n = ifn(age <= 45, 1, 2);
  end;
  %dt(randdtc, randdt)
  %dt(rfxstdtc, trtsdt)
  %dt(rfxendtc, trtedt)
  if length(rfxstdtc) >= 16 then
    trtsdtm = dhms(trtsdt, input(substr(rfxstdtc, 12, 2), 2.), input(substr(rfxstdtc, 15, 2), 2.), 0);
  format trtsdtm datetime20.;
  %dt(eosdtc, eosdt)
  eosstt = ifc(eosdecod = 'COMPLETED', 'COMPLETED', 'DISCONTINUED');
  if eosstt = 'DISCONTINUED' then dcsreas = eosdecod;
  randfl = ifc(randdt ne ., 'Y', 'N');
  saffl = ifc(randfl = 'Y' and trtsdt ne ., 'Y', 'N');
  immfl = ifc(saffl = 'Y' and immok = 'Y', 'Y', 'N');
  label
    studyid = 'Study Identifier'
    usubjid = 'Unique Subject Identifier'
    subjid  = 'Subject Identifier for the Study'
    siteid  = 'Study Site Identifier'
    age     = 'Age'
    ageu    = 'Age Units'
    agegr1  = 'Pooled Age Group 1'
    agegr1n = 'Pooled Age Group 1 (N)'
    sex     = 'Sex'
    race    = 'Race'
    ethnic  = 'Ethnicity'
    country = 'Country'
    trt01p  = 'Planned Treatment for Period 01'
    trt01pn = 'Planned Treatment for Period 01 (N)'
    trt01a  = 'Actual Treatment for Period 01'
    trt01an = 'Actual Treatment for Period 01 (N)'
    arm     = 'Description of Planned Arm'
    actarm  = 'Description of Actual Arm'
    armnrs  = 'Reason Arm and/or Actual Arm is Null'
    randdt  = 'Date of Randomization'
    trtsdt  = 'Date of First Exposure to Treatment'
    trtsdtm = 'Datetime of First Exposure to Treatment'
    trtedt  = 'Date of Last Exposure to Treatment'
    eosdt   = 'End of Study Date'
    eosstt  = 'End of Study Status'
    dcsreas = 'Reason for Discontinuation from Study'
    randfl  = 'Randomized Population Flag'
    saffl   = 'Safety Population Flag'
    immfl   = 'Immunogenicity PP Population Flag';
run;

%finalize(adsl1, adsl, Subject-Level Analysis Dataset, lib=adam,
  vars=STUDYID USUBJID SUBJID SITEID AGE AGEU AGEGR1 AGEGR1N SEX RACE ETHNIC COUNTRY TRT01P TRT01PN TRT01A TRT01AN ARM ACTARM ARMNRS
    RANDDT TRTSDT TRTSDTM TRTEDT EOSDT EOSSTT DCSREAS RANDFL SAFFL IMMFL,
  keys=STUDYID USUBJID)
