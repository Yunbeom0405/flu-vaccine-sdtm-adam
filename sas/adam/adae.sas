/*******************************************************************************
Program : adae.sas
Purpose : Create ADaM ADAE
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\adam\setup.sas";

proc format;
invalue sev (upcase)
'MILD' = 1
'MODERATE' = 2
'SEVERE' = 3;
run;

%addadsl(sdtm.ae, ae1, studyid trt01p trt01pn trt01a trt01an trtsdt agegr1 agegr1n saffl)

data ae2;
  set ae1;
  length astdtf $1;
  aesevn = input(aesev, sev.);
  %dt(aeendtc, aendt)
  if length(aestdtc) >= 10 then do;
    %dt(aestdtc, astdt)
  end;
  /* year-month only: dose date if same month, else first of month */
  else if length(aestdtc) = 7 and trtsdt ne . then do;
    astdt = ifn(substr(aestdtc, 1, 7) = put(trtsdt, yymmd7.), trtsdt, input(cats(aestdtc, '-01'), e8601da.));
    astdtf = 'D';
  end;
  format astdt date9.;
  %ady(astdt, astdy)
  %ady(aendt, aendy)
  if astdt ne . and trtsdt ne . and astdt >= trtsdt then trtemfl = 'Y';
  if aecat = 'UNSOLICITED' and trtemfl = 'Y' and astdy <= 22 then anl01fl = 'Y';
  if aeser = 'Y' and trtemfl = 'Y' and astdy <= 91 then anl02fl = 'Y';
run;

/* first occurrence flags among treatment-emergent records */
proc sort data=ae2(where=(trtemfl = 'Y')) out=o1;
  by usubjid astdt aeseq;
run;

data o1;
  set o1;
  by usubjid;
  if first.usubjid then aoccfl = 'Y';
  keep usubjid aeseq aoccfl;
run;

proc sort data=ae2(where=(trtemfl = 'Y')) out=o2;
  by usubjid aebodsys astdt aeseq;
run;

data o2;
  set o2;
  by usubjid aebodsys;
  if first.aebodsys then aoccsfl = 'Y';
  keep usubjid aeseq aoccsfl;
run;

proc sort data=ae2(where=(trtemfl = 'Y')) out=o3;
  by usubjid aebodsys aedecod astdt aeseq;
run;

data o3;
  set o3;
  by usubjid aebodsys aedecod;
  if first.aedecod then aoccpfl = 'Y';
  keep usubjid aeseq aoccpfl;
run;

proc sort data=ae2;
  by usubjid aeseq;
run;

proc sort data=o1;
  by usubjid aeseq;
run;

proc sort data=o2;
  by usubjid aeseq;
run;

proc sort data=o3;
  by usubjid aeseq;
run;

data adae3;
  merge ae2 o1 o2 o3;
  by usubjid aeseq;
  label
    studyid  = 'Study Identifier'
    usubjid  = 'Unique Subject Identifier'
    trt01p   = 'Planned Treatment for Period 01'
    trt01pn  = 'Planned Treatment for Period 01 (N)'
    trt01a   = 'Actual Treatment for Period 01'
    trt01an  = 'Actual Treatment for Period 01 (N)'
    trtsdt   = 'Date of First Exposure to Treatment'
    agegr1   = 'Pooled Age Group 1'
    agegr1n  = 'Pooled Age Group 1 (N)'
    saffl    = 'Safety Population Flag'
    aeseq    = 'Sequence Number'
    aeterm   = 'Reported Term for the Adverse Event'
    aedecod  = 'Dictionary-Derived Term'
    aebodsys = 'Body System or Organ Class'
    aecat    = 'Category for Adverse Event'
    aesev    = 'Severity/Intensity'
    aesevn   = 'Severity/Intensity (N)'
    aeser    = 'Serious Event'
    aerel    = 'Causality'
    aeacn    = 'Action Taken with Study Treatment'
    aeout    = 'Outcome of Adverse Event'
    aestdtc  = 'Start Date/Time of Adverse Event'
    aeendtc  = 'End Date/Time of Adverse Event'
    astdt    = 'Analysis Start Date'
    astdtf   = 'Analysis Start Date Imputation Flag'
    aendt    = 'Analysis End Date'
    astdy    = 'Analysis Start Relative Day'
    aendy    = 'Analysis End Relative Day'
    trtemfl  = 'Treatment Emergent Analysis Flag'
    anl01fl  = 'Analysis Flag 01'
    anl02fl  = 'Analysis Flag 02'
    aoccfl   = '1st Occurrence within Subject Flag'
    aoccsfl  = '1st Occurrence of SOC Flag'
    aoccpfl  = '1st Occurrence of Preferred Term Flag';
run;

%finalize(adae3, adae, Adverse Events Analysis Dataset, lib=adam,
  vars=
    STUDYID USUBJID TRT01P TRT01PN TRT01A TRT01AN TRTSDT AGEGR1 AGEGR1N SAFFL AESEQ AETERM AEDECOD
    AEBODSYS AECAT AESEV AESEVN AESER AEREL AEACN AEOUT AESTDTC AEENDTC ASTDT ASTDTF AENDT ASTDY AENDY TRTEMFL
    ANL01FL ANL02FL AOCCFL AOCCSFL AOCCPFL,
  keys=STUDYID USUBJID AESEQ)
