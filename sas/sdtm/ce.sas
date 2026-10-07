/*******************************************************************************
Program : ce.sas
Purpose : Create SDTM CE
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

/* grade per reaction and diary day: severity scale, diameter (mm) */
%macro grades(in, out, window);
data &out;
  length usubjid ceterm cescat kind dtc $200;
  set &in;
  array sev{9} pain tenderness chills malaise myalgia headache arthralgia nausea vomiting;
  array sevn{9} $12 _temporary_ ('PAIN', 'TENDERNESS', 'CHILLS', 'MALAISE', 'MYALGIA',
    'HEADACHE', 'ARTHRALGIA', 'NAUSEA', 'VOMITING');
  array mm{3} redness_mm swelling_mm induration_mm;
  array mmn{3} $12 _temporary_ ('REDNESS', 'SWELLING', 'INDURATION');

  usubjid = cats('VAXF101-', subject);
  window = &window;
  %if &window = 7 %then %do; %iso(diarydat, dtc) %end;
  %else %do; %iso(obsdat, dtc) %end;

  kind = 'SEV';
  do i = 1 to 9;
    if missing(sev{i}) then continue;
    ceterm = sevn{i};
    cescat = ifc(i <= 2, 'LOCAL', 'SYSTEMIC');
    grade = max(0, whichc(upcase(sev{i}), 'NONE', 'MILD', 'MODERATE', 'SEVERE') - 1);
    output;
  end;

  kind = 'TOX';
  do i = 1 to 3;
    if missing(mm{i}) then continue;
    ceterm = mmn{i};
    cescat = 'LOCAL';
    _mm = input(mm{i}, best12.);
    grade = (_mm >= 25) + (_mm > 50) + (_mm > 100);
    output;
  end;
  keep usubjid ceterm cescat kind window dtc grade;
run;
%mend grades;

%grades(raw_diary, gr_d, 7)
%grades(raw_obs30, gr_o, 0)

/* fever from the diary temperature in VS */
data gr_f;
  length usubjid ceterm cescat kind dtc $200;
  set sdtm.vs(where=(vstestcd = 'TEMP' and vsscat = 'SYSTEMIC'));
  ceterm = 'FEVER';
  cescat = 'SYSTEMIC';
  kind = 'TOX';
  window = 7;
  dtc = vsdtc;
  grade = (vsstresn >= 38) + (vsstresn >= 38.5) + (vsstresn >= 39) + (vsstresn > 40);
  keep usubjid ceterm cescat kind window dtc grade;
run;

data gr;
  set gr_d gr_o gr_f;
  dnum = input(dtc, e8601da.);
run;

/* one record per subject, reaction and window */
proc sql;
  create table ce0 as
  select usubjid, ceterm, cescat, kind, window, max(grade) as maxgr,
    min(case when grade >= 1 then dnum end) as d1,
    max(case when grade >= 1 then dnum end) as d2
  from gr
  group by usubjid, ceterm, cescat, kind, window;

  create table ce1 as
  select a.*, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from ce0 as a left join sdtm.dm as d on a.usubjid = d.usubjid
  order by a.usubjid, a.ceterm, a.window;
quit;

data ce2;
  length studyid domain cegrpid cedecod cecat cepresp ceoccur cesev cetoxgr
    cestdtc ceendtc cetpt ceevintx cetptref cerftdtc epoch _d $200;
  set ce1;
  by usubjid;

  studyid = 'VAXF101';
  domain = 'CE';
  if first.usubjid then ceseq = 0;
  ceseq + 1;
  cegrpid = cats('VACCINATION 1-', ceterm);
  cedecod = ceterm;
  cecat = 'REACTOGENICITY';
  cepresp = 'Y';

  ceoccur = ifc(maxgr >= 1, 'Y', 'N');
  if maxgr >= 1 then do;
    if kind = 'SEV' then cesev = choosec(maxgr, 'MILD', 'MODERATE', 'SEVERE');
    else cetoxgr = strip(put(maxgr, 1.));
    cestdtc = put(d1, e8601da.);
    ceendtc = put(d2, e8601da.);
  end;

  if window = 0 then do;
    cetpt = '30 MINUTES POST-DOSE';
    cetptnum = 0;
    ceevintx = 'WITHIN 30 MINUTES AFTER VACCINATION';
  end;
  else do;
    cetpt = 'DAY 7';
    cetptnum = 7;
    ceevintx = 'WITHIN 7 DAYS AFTER VACCINATION';
  end;
  cetptref = 'VACCINATION';
  cerftdtc = rfxstdtc;

  _d = coalescec(cestdtc, substr(rfxstdtc, 1, 10));
  %epoch(_d)
  %dy(cestdtc, cestdy)
  %dy(ceendtc, ceendy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    ceseq    = 'Sequence Number'
    cegrpid  = 'Group ID'
    ceterm   = 'Reported Term for the Clinical Event'
    cedecod  = 'Dictionary-Derived Term'
    cecat    = 'Category for the Clinical Event'
    cescat   = 'Subcategory for the Clinical Event'
    cepresp  = 'Clinical Event Pre- specified'
    ceoccur  = 'Clinical Event Occurrence'
    cesev    = 'Severity/Intensity'
    cetoxgr  = 'Standard Toxicity Grade'
    epoch    = 'Epoch'
    cestdtc  = 'Start Date/Time of Clinical Event'
    ceendtc  = 'End Date/Time of Clinical Event'
    cestdy   = 'Study Day of Start of Event'
    ceendy   = 'Study Day of End of Event'
    cetpt    = 'Planned Time Point Name'
    cetptnum = 'Planned Time Point Number'
    cetptref = 'Time Point Reference'
    cerftdtc = 'Date/Time of Reference Time Point'
    ceevintx = 'Evaluation Interval Text';
run;

%finalize(ce2, ce, Clinical Events,
  vars=STUDYID DOMAIN USUBJID CESEQ CEGRPID CETERM CEDECOD CECAT CESCAT CEPRESP
    CEOCCUR CESEV CETOXGR EPOCH CESTDTC CEENDTC CESTDY CEENDY CETPT CETPTNUM
    CETPTREF CERFTDTC CEEVINTX,
  keys=STUDYID USUBJID CEDECOD CETPTNUM)
