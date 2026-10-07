/*******************************************************************************
Program : adce.sas
Purpose : Create ADaM ADCE
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\adam\setup.sas";

proc format;
invalue sev (upcase)
'MILD' = 1
'MODERATE' = 2
'SEVERE' = 3;
run;

data ce0;
  set sdtm.ce;
  length atoxgr $1 atpt $24;
  if ceoccur = 'N' then atoxgr = '0';
  else if cetoxgr ne '' then atoxgr = cetoxgr;
  else atoxgr = put(input(cesev, sev.), 1.);
  atoxgrn = input(atoxgr, 1.);
  if cetpt = '30 MINUTES POST-DOSE' then do;
    atpt = cetpt;
    atptn = 0;
  end;
  else do;
    atpt = 'WITHIN 7 DAYS POST-DOSE';
    atptn = 8;
  end;
  %dt(cestdtc, astdt)
  %dt(ceendtc, aendt)
  keep usubjid ceseq ceterm cedecod cescat ceoccur atoxgr atoxgrn atpt atptn astdt aendt;
run;

%addadsl(ce0, ce1, studyid trt01p trt01pn trt01a trt01an trtsdt agegr1 agegr1n saffl)

/* first occurrence flags: highest grade first, ties by sequence */
proc sort data=ce1(where=(ceoccur = 'Y')) out=occ1;
  by usubjid atptn descending atoxgrn ceseq;
run;

data occ1;
  set occ1;
  by usubjid atptn;
  if first.atptn then aoccfl = 'Y';
  keep usubjid cedecod atptn aoccfl;
run;

proc sort data=ce1(where=(ceoccur = 'Y')) out=occ2;
  by usubjid atptn cescat descending atoxgrn ceseq;
run;

data occ2;
  set occ2;
  by usubjid atptn cescat;
  if first.cescat then aoccsfl = 'Y';
  keep usubjid cedecod atptn aoccsfl;
run;

proc sort data=ce1;
  by usubjid cedecod atptn;
run;

proc sort data=occ1;
  by usubjid cedecod atptn;
run;

proc sort data=occ2;
  by usubjid cedecod atptn;
run;

data adce3;
  merge ce1 occ1 occ2;
  by usubjid cedecod atptn;
  length aoccpfl $1;
  if ceoccur = 'Y' then aoccpfl = 'Y';
  %ady(astdt, astdy)
  %ady(aendt, aendy)
  label
    studyid = 'Study Identifier'
    usubjid = 'Unique Subject Identifier'
    trt01p  = 'Planned Treatment for Period 01'
    trt01pn = 'Planned Treatment for Period 01 (N)'
    trt01a  = 'Actual Treatment for Period 01'
    trt01an = 'Actual Treatment for Period 01 (N)'
    trtsdt  = 'Date of First Exposure to Treatment'
    agegr1  = 'Pooled Age Group 1'
    agegr1n = 'Pooled Age Group 1 (N)'
    saffl   = 'Safety Population Flag'
    ceseq   = 'Sequence Number'
    ceterm  = 'Reported Term for the Clinical Event'
    cedecod = 'Dictionary-Derived Term'
    cescat  = 'Subcategory for Clinical Event'
    ceoccur = 'Clinical Event Occurrence'
    atoxgr  = 'Analysis Toxicity Grade'
    atoxgrn = 'Analysis Toxicity Grade (N)'
    atpt    = 'Analysis Timepoint'
    atptn   = 'Analysis Timepoint (N)'
    astdt   = 'Analysis Start Date'
    aendt   = 'Analysis End Date'
    astdy   = 'Analysis Start Relative Day'
    aendy   = 'Analysis End Relative Day'
    aoccfl  = '1st Occurrence within Subject Flag'
    aoccsfl = '1st Occurrence of SOC Flag'
    aoccpfl = '1st Occurrence of Preferred Term Flag';
run;

%finalize(adce3, adce, Clinical Events Analysis Dataset, lib=adam,
  vars=
    STUDYID USUBJID TRT01P TRT01PN TRT01A TRT01AN TRTSDT AGEGR1 AGEGR1N SAFFL CESEQ CETERM CEDECOD
    CESCAT CEOCCUR ATOXGR ATOXGRN ATPT ATPTN ASTDT AENDT ASTDY AENDY AOCCFL AOCCSFL AOCCPFL,
  keys=STUDYID USUBJID CEDECOD ATPTN)
