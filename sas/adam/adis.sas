/*******************************************************************************
Program : adis.sas
Purpose : Create ADaM ADIS
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\adam\setup.sas";

data is0;
  set sdtm.is;
  length paramcd srcdom srcvar $8 param $40 avalc $8 avisit $8;
  paramcd = cats('HAI', substr(isbdagnt, 8, 1));
  param = catx(', ', 'HAI Titer', propcase(isbdagnt));
  paramn = rank(substr(isbdagnt, 8, 1)) - 64;
  avalc = isstresc;
  if isstat = '' then aval = ifn(isstresc = '<10', islloq / 2, isstresn);
  lloq = islloq;
  %dt(isdtc, adt)
  avisit = visit;
  avisitn = visitnum;
  srcdom = 'IS';
  srcvar = 'ISSTRESC';
  srcseq = isseq;
  keep usubjid paramcd param paramn avalc aval lloq adt avisit avisitn islobxfl srcdom srcvar srcseq;
run;

%addadsl(is0, is1, studyid trt01p trt01pn trt01a trt01an trtsdt agegr1 agegr1n saffl immfl)

/* baseline: last pre-dose record with a result, carried to the subject and parameter */
proc sql;
  create table base as
  select usubjid, paramcd, aval as base, avalc as basec
  from is1 where islobxfl = 'Y' and aval ne .;
quit;

proc sort data=is1;
  by usubjid paramcd avisitn;
run;

proc sort data=base;
  by usubjid paramcd;
run;

data is2;
  merge is1(in=_in) base;
  by usubjid paramcd;
  if _in;
  length ablfl crit1fl crit2fl anl01fl $1 basecat1 $4 crit1 crit2 $20;
  %ady(adt, ady)
  if islobxfl = 'Y' and aval ne . then ablfl = 'Y';
  if basec ne '' then basecat1 = ifc(basec = '<10', '<10', '>=10');
  if avisitn = 4 and aval ne . and base ne . then r2base = aval / base;
  crit1 = 'Titer >= 40';
  if aval ne . then crit1fl = ifc(aval >= 40, 'Y', 'N');
  if avisitn = 4 then do;
    crit2 = 'Seroconversion';
    if aval ne . and base ne . then
      crit2fl = ifc((basecat1 = '<10' and aval >= 40) or (basecat1 = '>=10' and r2base >= 4), 'Y', 'N');
  end;
  if immfl = 'Y' and aval ne . then anl01fl = 'Y';
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
    immfl    = 'Immunogenicity PP Population Flag'
    paramcd  = 'Parameter Code'
    param    = 'Parameter'
    paramn   = 'Parameter (N)'
    aval     = 'Analysis Value'
    avalc    = 'Analysis Value (C)'
    lloq     = 'Lower Limit of Quantification'
    adt      = 'Analysis Date'
    ady      = 'Analysis Relative Day'
    avisit   = 'Analysis Visit'
    avisitn  = 'Analysis Visit (N)'
    ablfl    = 'Baseline Record Flag'
    base     = 'Baseline Value'
    basec    = 'Baseline Value (C)'
    basecat1 = 'Baseline Category 1'
    r2base   = 'Ratio to Baseline'
    crit1    = 'Analysis Criterion 1'
    crit1fl  = 'Criterion 1 Evaluation Result Flag'
    crit2    = 'Analysis Criterion 2'
    crit2fl  = 'Criterion 2 Evaluation Result Flag'
    anl01fl  = 'Analysis Flag 01'
    srcdom   = 'Source Data'
    srcvar   = 'Source Variable'
    srcseq   = 'Source Sequence Number';
run;

data is3;
  set is2;
  by usubjid paramcd;
  length parcat1 $8;
  parcat1 = 'HAI';
  if first.usubjid then aseq = 0;
  aseq + 1;
  label
    parcat1 = 'Parameter Category 1'
    aseq    = 'Analysis Sequence Number';
run;

%finalize(is3, adis, Immunogenicity Analysis Dataset, lib=adam,
  vars=STUDYID USUBJID TRT01P TRT01PN TRT01A TRT01AN TRTSDT AGEGR1 AGEGR1N SAFFL IMMFL PARAMCD PARAM PARAMN PARCAT1
    AVAL AVALC LLOQ ADT ADY AVISIT AVISITN ABLFL BASE BASEC BASECAT1 R2BASE CRIT1 CRIT1FL CRIT2 CRIT2FL ANL01FL
    ASEQ SRCDOM SRCVAR SRCSEQ,
  keys=STUDYID USUBJID PARAMCD AVISITN)
