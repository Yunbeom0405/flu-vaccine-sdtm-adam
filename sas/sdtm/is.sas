/*******************************************************************************
Program : is.sas
Purpose : Create SDTM IS
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

proc sql;
  create table is0 as
  select a.*, d.usubjid, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from raw_lb_hai as a
  left join sdtm.dm as d on cats('VAXF101-', a.subject) = d.usubjid;
quit;

data is1;
  length studyid domain istestcd istest isbdagnt iscat isorres isorresu isstresc
    isstresu isstat isreasnd isspec ismethod isdtc epoch isornrlo isornrhi isnrind $200;
  set is0(rename=(result=_res visit=_visit));
  _row = _n_;
  isstnrlo = .;
  isstnrhi = .;

  studyid = 'VAXF101';
  domain = 'IS';
  istestcd = 'MBFAB';
  istest = 'Functional Microbial-induced Antibody';
  isbdagnt = upcase(substr(analyte, 5));
  iscat = 'IMMUNOGENICITY';
  isspec = 'SERUM';
  ismethod = 'HEMAGGLUTINATION INHIBITION ASSAY';
  islloq = 10;

  visitnum = input(_visit, visitn.);
  visit = upcase(_visit);

  /* below LLOQ keeps the text, no numeric result */
  if missing(_res) then do;
    isstat = 'NOT DONE';
    isreasnd = upcase(comment);
  end;
  else do;
    isorres = _res;
    isorresu = unit;
    isstresc = _res;
    isstresu = unit;
    if _res ne '<10' then isstresn = input(_res, best12.);
  end;

  isdtc = colldat;
  %predose
  %fepoch(isdtc)
  %dy(isdtc, isdy)
run;

%lobxfl(is1, islobxfl, by=isbdagnt, res=isstresc, dtc=isdtc)

proc sort data=is1;
  by usubjid istestcd isbdagnt visitnum;
run;

data is2;
  set is1;
  by usubjid;
  if first.usubjid then isseq = 0;
  isseq + 1;
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    isseq    = 'Sequence Number'
    istestcd = 'Immunogenicity Test/Exam Short Name'
    istest   = 'Immunogenicity Test or Examination Name'
    isbdagnt = 'Binding Agent'
    iscat    = 'Category for Immunogenicity Test'
    isorres  = 'Results or Findings in Original Units'
    isorresu = 'Original Units'
    isornrlo = 'Reference Range Lower Limit-Orig Unit'
    isornrhi = 'Reference Range Upper Limit-Orig Unit'
    isstresc = 'Character Result/Finding in Std Format'
    isstresn = 'Numeric Results/Findings in Std. Units'
    isstresu = 'Standard Units'
    isstnrlo = 'Reference Range Lower Limit-Std Unit'
    isstnrhi = 'Reference Range Upper Limit-Std Unit'
    isnrind  = 'Reference Range Indicator'
    isstat   = 'Completion Status'
    isreasnd = 'Reason Not Done'
    isspec   = 'Specimen Type'
    ismethod = 'Method of Test or Examination'
    islobxfl = 'Last Observation Before Exposure Flag'
    islloq   = 'Lower Limit of Quantitation'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    epoch    = 'Epoch'
    isdtc    = 'Date/Time of Collection'
    isdy     = 'Study Day of Visit/Collection/Exam';
run;

%finalize(is2, is, Immunogenicity Specimen Assessments,
  vars=STUDYID DOMAIN USUBJID ISSEQ ISTESTCD ISTEST ISBDAGNT ISCAT ISORRES ISORRESU
    ISORNRLO ISORNRHI ISSTRESC ISSTRESN ISSTRESU ISSTNRLO ISSTNRHI ISNRIND ISSTAT
    ISREASND ISSPEC ISMETHOD ISLOBXFL ISLLOQ
    VISITNUM VISIT EPOCH ISDTC ISDY,
  keys=STUDYID USUBJID ISTESTCD ISBDAGNT VISITNUM)
