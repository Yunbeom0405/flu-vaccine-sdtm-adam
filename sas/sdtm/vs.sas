/*******************************************************************************
Program : vs.sas
Purpose : Create SDTM VS
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

/* visit vitals, one record per test */
data vs_a;
  length subject visit vsdat vstestcd vsorres vsorresu vscat vsscat vstpt $200;
  set raw_vitals;
  visitnum = input(visit, visitn.);
  visit = upcase(visit);
  vstptnum = .;
  vstestcd = 'SYSBP'; vsorres = sysbp; vsorresu = 'mmHg'; output;
  vstestcd = 'DIABP'; vsorres = diabp; vsorresu = 'mmHg'; output;
  vstestcd = 'PULSE'; vsorres = pulse; vsorresu = 'beats/min'; output;
  vstestcd = 'TEMP'; vsorres = temp; vsorresu = tempu; output;
  keep subject visitnum visit vsdat vstestcd vsorres vsorresu vscat vsscat vstpt vstptnum;
run;

/* diary temperature, reactogenicity */
data vs_b;
  length subject visit vsdat vstestcd vsorres vsorresu vscat vsscat vstpt $200;
  set raw_diary(keep=subject diaryday diarydat temp tempu);
  vsdat = diarydat;
  visitnum = .;
  vstestcd = 'TEMP';
  vsorres = temp;
  vsorresu = tempu;
  vscat = 'REACTOGENICITY';
  vsscat = 'SYSTEMIC';
  vstpt = catx(' ', 'DAY', diaryday);
  vstptnum = input(diaryday, 2.);
  keep subject visitnum visit vsdat vstestcd vsorres vsorresu vscat vsscat vstpt vstptnum;
run;

proc sql;
  create table vs0 as
  select a.*, d.usubjid, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from (select * from vs_a union all corresponding select * from vs_b) as a
  left join sdtm.dm as d on cats('VAXF101-', a.subject) = d.usubjid;
quit;

data vs1;
  length studyid domain vstest vsstresc vsstresu vsrftdtc vstptref epoch vsdtc $200;
  set vs0;
  _row = _n_;

  studyid = 'VAXF101';
  domain = 'VS';
  vstest = choosec(whichc(vstestcd, 'SYSBP', 'DIABP', 'PULSE', 'TEMP'),
    'Systolic Blood Pressure', 'Diastolic Blood Pressure', 'Pulse Rate', 'Temperature');

  /* temperature is stored in C */
  vsstresn = input(vsorres, best12.);
  if vstestcd = 'TEMP' then do;
    if vsorresu = 'F' then vsstresn = (vsstresn - 32) * 5 / 9;
    vsstresn = round(vsstresn, 0.1);
    vsstresu = 'C';
    vsstresc = strip(put(vsstresn, 8.1));
  end;
  else do;
    vsstresu = vsorresu;
    vsstresc = strip(put(vsstresn, 8.));
  end;

  if not missing(vstptnum) then do;
    vstptref = 'VACCINATION';
    vsrftdtc = rfxstdtc;
  end;

  %iso(vsdat, vsdtc)
  %predose
  %fepoch(vsdtc)
  %dy(vsdtc, vsdy)
run;

%lobxfl(vs1, vslobxfl, by=vstestcd, res=vsstresn, dtc=vsdtc)

proc sort data=vs1;
  by usubjid vstestcd visitnum vsdtc vstptnum;
run;

data vs2;
  set vs1;
  by usubjid;
  if first.usubjid then vsseq = 0;
  vsseq + 1;
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    vsseq    = 'Sequence Number'
    vstestcd = 'Vital Signs Test Short Name'
    vstest   = 'Vital Signs Test Name'
    vscat    = 'Category for Vital Signs'
    vsscat   = 'Subcategory for Vital Signs'
    vsorres  = 'Result or Finding in Original Units'
    vsorresu = 'Original Units'
    vsstresc = 'Character Result/Finding in Std Format'
    vsstresn = 'Numeric Result/Finding in Standard Units'
    vsstresu = 'Standard Units'
    vslobxfl = 'Last Observation Before Exposure Flag'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    epoch    = 'Epoch'
    vsdtc    = 'Date/Time of Measurements'
    vsdy     = 'Study Day of Vital Signs'
    vstpt    = 'Planned Time Point Name'
    vstptnum = 'Planned Time Point Number'
    vstptref = 'Time Point Reference'
    vsrftdtc = 'Date/Time of Reference Time Point';
run;

%finalize(vs2, vs, Vital Signs,
  vars=STUDYID DOMAIN USUBJID VSSEQ VSTESTCD VSTEST VSCAT VSSCAT VSORRES VSORRESU
    VSSTRESC VSSTRESN VSSTRESU VSLOBXFL VISITNUM VISIT EPOCH VSDTC VSDY VSTPT
    VSTPTNUM VSTPTREF VSRFTDTC,
  keys=STUDYID USUBJID VSTESTCD VISITNUM VSDTC VSTPTNUM)
