/*******************************************************************************
Program : face.sas
Purpose : Create SDTM FACE (domain FA)
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

proc format;
value $fatest
'OCCUR' = 'Occurrence Indicator'
'SEV' = 'Severity/Intensity'
'DIAMETER' = 'Diameter';
run;

/* one diary row or 30-minute check -> one record per reaction and test */
data fa0;
  length subject fatpt fadat faobj fascat fatestcd faorres faorresu $200;
  set raw_diary(in=a) raw_obs30(in=b);
  array sev{9} pain tenderness chills malaise myalgia headache arthralgia nausea vomiting;
  array sevn{9} $12 _temporary_ ('PAIN', 'TENDERNESS', 'CHILLS', 'MALAISE', 'MYALGIA',
    'HEADACHE', 'ARTHRALGIA', 'NAUSEA', 'VOMITING');
  array mm{3} redness_mm swelling_mm induration_mm;
  array mmn{3} $12 _temporary_ ('REDNESS', 'SWELLING', 'INDURATION');

  if a then do;
    fatpt = catx(' ', 'DAY', diaryday);
    fatptnum = input(diaryday, 2.);
    fadat = diarydat;
  end;
  else do;
    fatpt = '30 MINUTES POST-DOSE';
    fatptnum = 0;
    fadat = obsdat;
  end;

  do i = 1 to 9;
    if missing(sev{i}) then continue;
    faobj = sevn{i};
    fascat = ifc(i <= 2, 'LOCAL', 'SYSTEMIC');
    fatestcd = 'OCCUR';
    faorres = ifc(upcase(sev{i}) = 'NONE', 'N', 'Y');
    faorresu = '';
    output;
    if faorres = 'Y' then do;
      fatestcd = 'SEV';
      faorres = upcase(sev{i});
      output;
    end;
  end;

  do i = 1 to 3;
    if missing(mm{i}) then continue;
    faobj = mmn{i};
    fascat = 'LOCAL';
    fatestcd = 'DIAMETER';
    faorres = mm{i};
    faorresu = 'mm';
    output;
  end;
  keep subject fatpt fatptnum fadat faobj fascat fatestcd faorres faorresu;
run;

proc sql;
  create table fa1 as
  select a.*, d.usubjid, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from fa0 as a
  left join sdtm.dm as d on cats('VAXF101-', a.subject) = d.usubjid
  order by d.usubjid, a.faobj, a.fatestcd, a.fatptnum;
quit;

data fa2;
  length studyid domain fagrpid fatest facat faeval fastresc fastresu fatptref
    farftdtc visit epoch fadtc $200;
  set fa1;
  by usubjid;

  studyid = 'VAXF101';
  domain = 'FA';
  if first.usubjid then faseq = 0;
  faseq + 1;
  fagrpid = cats('VACCINATION 1-', faobj);
  fatest = put(fatestcd, $fatest.);
  facat = 'REACTOGENICITY';
  faeval = 'STUDY SUBJECT';
  fastresc = faorres;
  if fatestcd = 'DIAMETER' then do;
    fastresn = input(faorres, best12.);
    fastresu = faorresu;
  end;
  fatptref = 'VACCINATION';
  /* time point 0 and diary day 1 belong to the Day 1 visit, diary days 2-7 to the Day 8 review */
  if fatptnum <= 1 then do;
    visitnum = 2;
    visit = 'DAY 1';
  end;
  else do;
    visitnum = 3;
    visit = 'DAY 8';
  end;
  farftdtc = rfxstdtc;

  %iso(fadat, fadtc)
  %epoch(fadtc)
  %dy(fadtc, fady)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    faseq    = 'Sequence Number'
    fagrpid  = 'Group ID'
    fatestcd = 'Findings About Test Short Name'
    fatest   = 'Findings About Test Name'
    faobj    = 'Object of the Observation'
    facat    = 'Category for Findings About'
    fascat   = 'Subcategory for Findings About'
    faorres  = 'Result or Finding in Original Units'
    faorresu = 'Original Units'
    fastresc = 'Character Result/Finding in Std Format'
    fastresn = 'Numeric Result/Finding in Standard Units'
    fastresu = 'Standard Units'
    faeval   = 'Evaluator'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    epoch    = 'Epoch'
    fadtc    = 'Date/Time of Collection'
    fady     = 'Study Day of Collection'
    fatpt    = 'Planned Time Point Name'
    fatptnum = 'Planned Time Point Number'
    fatptref = 'Time Point Reference'
    farftdtc = 'Date/Time of Reference Time Point';
run;

%finalize(fa2, face, Findings About Events or Interventions,
  vars=STUDYID DOMAIN USUBJID FASEQ FAGRPID FATESTCD FATEST FAOBJ FACAT FASCAT
    FAORRES FAORRESU FASTRESC FASTRESN FASTRESU FAEVAL VISITNUM VISIT EPOCH FADTC FADY FATPT
    FATPTNUM FATPTREF FARFTDTC,
  keys=STUDYID USUBJID FAOBJ FATESTCD FATPTNUM)
