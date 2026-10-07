/*******************************************************************************
Program : adface.sas
Purpose : Create ADaM ADFACE
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\adam\setup.sas";

/* parameter code and order per reaction */
proc format;
invalue paramn
'PAIN' = 1
'TENDERN' = 2
'REDNESS' = 3
'SWELLING' = 4
'INDURAT' = 5
'FEVER' = 6
'CHILLS' = 7
'MALAISE' = 8
'MYALGIA' = 9
'HEADACHE' = 10
'ARTHRALG' = 11
'NAUSEA' = 12
'VOMITING' = 13;
value $paramcd
'TENDERNESS' = 'TENDERN'
'INDURATION' = 'INDURAT'
'ARTHRALGIA' = 'ARTHRALG'
other = [$8.];
invalue sev (upcase)
'MILD' = 1
'MODERATE' = 2
'SEVERE' = 3;
run;

/* severity-scale reactions: occurrence record, severity record only when it occurred */
proc sql;
  create table sev as
  select usubjid, faobj, fatpt, fastresc as sev, faseq as sevseq
  from sdtm.face where fatestcd = 'SEV';
quit;

proc sort data=sev;
  by usubjid faobj fatpt;
run;

proc sort data=sdtm.face(where=(fatestcd = 'OCCUR' and faobj not in ('REDNESS', 'SWELLING', 'INDURATION'))) out=occ;
  by usubjid faobj fatpt;
run;

data face_sev;
  merge occ(in=_in) sev;
  by usubjid faobj fatpt;
  if _in;
  length srcdom srcvar $8;
  if fastresc = 'N' then aval = 0;
  else aval = input(sev, sev.);
  srcdom = 'FA';
  srcvar = 'FASTRESC';
  srcseq = ifn(fastresc = 'N', faseq, sevseq);
run;

/* diameter reactions: below 25 mm is grade 0 */
data face_dia;
  set sdtm.face(where=(fatestcd = 'DIAMETER'));
  length srcdom srcvar $8 measu $2;
  measval = fastresn;
  aval = ifn(measval < 25, 0, ifn(measval <= 50, 1, ifn(measval <= 100, 2, 3)));
  measu = 'mm';
  srcdom = 'FA';
  srcvar = 'FASTRESN';
  srcseq = faseq;
run;

/* fever: diary temperature in VS, days 1-7 only */
data face_tmp;
  set sdtm.vs(where=(vstestcd = 'TEMP' and vscat = 'REACTOGENICITY'));
  length srcdom srcvar $8 measu $2 faobj fatpt $40 fadtc $20;
  faobj = 'FEVER';
  fatpt = vstpt;
  fadtc = vsdtc;
  measval = vsstresn;
  aval = ifn(measval < 38, 0, ifn(measval < 38.5, 1, ifn(measval < 39, 2, ifn(measval <= 40, 3, 4))));
  measu = 'C';
  srcdom = 'VS';
  srcvar = 'VSSTRESN';
  srcseq = vsseq;
run;

data face0;
  set face_sev face_dia face_tmp;
  length paramcd $8 param $40 parcat1 $8 atpt $24;
  paramcd = put(faobj, $paramcd.);
  paramn = input(paramcd, paramn.);
  param = catx(' ', propcase(faobj), 'Grade');
  parcat1 = ifc(faobj in ('PAIN', 'TENDERNESS', 'REDNESS', 'SWELLING', 'INDURATION'), 'LOCAL', 'SYSTEMIC');
  atpt = fatpt;
  atptn = ifn(atpt = '30 MINUTES POST-DOSE', 0, input(substr(atpt, 5), 2.));
  %dt(fadtc, adt)
  keep usubjid paramcd param paramn parcat1 aval measval measu adt atpt atptn srcdom srcvar srcseq;
run;

%addadsl(face0, face1, studyid trt01p trt01pn trt01a trt01an trtsdt agegr1 agegr1n saffl)

proc sort data=face1;
  by usubjid paramn atptn;
run;

data adface3;
  set face1;
  by usubjid;
  %ady(adt, ady)
  if first.usubjid then aseq = 0;
  aseq + 1;
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
    paramcd = 'Parameter Code'
    param   = 'Parameter'
    paramn  = 'Parameter (N)'
    parcat1 = 'Parameter Category 1'
    aval    = 'Analysis Value'
    measval = 'Measured Value'
    measu   = 'Measured Value Unit'
    adt     = 'Analysis Date'
    ady     = 'Analysis Relative Day'
    atpt    = 'Analysis Timepoint'
    atptn   = 'Analysis Timepoint (N)'
    aseq    = 'Analysis Sequence Number'
    srcdom  = 'Source Data'
    srcvar  = 'Source Variable'
    srcseq  = 'Source Sequence Number';
run;

%finalize(adface3, adface, Reactogenicity Findings Analysis Dataset, lib=adam,
  vars=
    STUDYID USUBJID TRT01P TRT01PN TRT01A TRT01AN TRTSDT AGEGR1 AGEGR1N SAFFL PARAMCD PARAM PARAMN
    PARCAT1 AVAL MEASVAL MEASU ADT ADY ATPT ATPTN ASEQ SRCDOM SRCVAR SRCSEQ,
  keys=STUDYID USUBJID PARAMCD ATPTN)
