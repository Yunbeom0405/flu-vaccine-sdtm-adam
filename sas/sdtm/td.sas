/*******************************************************************************
Program : td.sas
Purpose : Create SDTM trial design datasets TA, TE, TV, TI, TS
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

/* run after dm.sas: TS takes dates and counts from DM */

data ta;
  length studyid domain armcd arm etcd element epoch tabranch tatrans $200;
  infile datalines dlm='|' truncover;
  input armcd arm taetord etcd element epoch;
  studyid = 'VAXF101';
  domain = 'TA';
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    armcd    = 'Planned Arm Code'
    arm      = 'Description of Planned Arm'
    taetord  = 'Planned Order of Element within Arm'
    etcd     = 'Element Code'
    element  = 'Description of Element'
    tabranch = 'Branch'
    tatrans  = 'Transition Rule'
    epoch    = 'Epoch';
datalines;
VAXF|VAXF-101 0.5 mL|1|SCRN|Screening|SCREENING
VAXF|VAXF-101 0.5 mL|2|VAX|Vaccination VAXF-101|TREATMENT
VAXF|VAXF-101 0.5 mL|3|FUP|Follow-up|FOLLOW-UP
PBO|Placebo|1|SCRN|Screening|SCREENING
PBO|Placebo|2|PBO|Vaccination Placebo|TREATMENT
PBO|Placebo|3|FUP|Follow-up|FOLLOW-UP
;
run;

data te;
  length studyid domain etcd element testrl teenrl tedur $200;
  infile datalines dlm='|' truncover;
  input etcd element testrl teenrl tedur;
  studyid = 'VAXF101';
  domain = 'TE';
  label
    studyid = 'Study Identifier'
    domain  = 'Domain Abbreviation'
    etcd    = 'Element Code'
    element = 'Description of Element'
    testrl  = 'Rule for Start of Element'
    teenrl  = 'Rule for End of Element'
    tedur   = 'Planned Duration of Element';
datalines;
SCRN|Screening|Informed consent|Randomization|P14D
VAX|Vaccination VAXF-101|Vaccination with VAXF-101|End of Day 1|P1D
PBO|Vaccination Placebo|Vaccination with placebo|End of Day 1|P1D
FUP|Follow-up|Day 2|Day 91 visit|P90D
;
run;

data tv;
  length studyid domain armcd arm visit tvstrl tvenrl $200;
  studyid = 'VAXF101';
  domain = 'TV';
  do a = 1 to 2;
    armcd = scan('VAXF PBO', a);
    arm = choosec(a, 'VAXF-101 0.5 mL', 'Placebo');
    do visitnum = 1 to 5;
      visit = choosec(visitnum, 'SCREENING', 'DAY 1', 'DAY 8', 'DAY 22', 'DAY 91');
      visitdy = choosen(visitnum, ., 1, 8, 22, 91);
      tvstrl = choosec(visitnum, 'Up to 14 days before vaccination', 'Vaccination day',
        '7 days after vaccination, +2 days', '21 days after vaccination, +/-3 days',
        '90 days after vaccination, +/-7 days');
      output;
    end;
  end;
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    visitdy  = 'Planned Study Day of Visit'
    armcd    = 'Planned Arm Code'
    arm      = 'Description of Planned Arm'
    tvstrl   = 'Visit Start Rule'
    tvenrl   = 'Visit End Rule';
run;

data ti;
  length studyid domain ietestcd iecat ietest tivers $200;
  infile datalines dlm='|' truncover;
  input ietestcd iecat ietest;
  studyid = 'VAXF101';
  domain = 'TI';
  tivers = '1';
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    ietestcd = 'Incl/Excl Criterion Short Name'
    ietest   = 'Inclusion/Exclusion Criterion'
    iecat    = 'Inclusion/Exclusion Category'
    tivers   = 'Protocol Criteria Versions';
datalines;
INCL01|INCLUSION|Aged 18 through 60 years at screening
INCL02|INCLUSION|Healthy and medically stable
INCL03|INCLUSION|Able to attend all scheduled visits and comply with study procedures
EXCL01|EXCLUSION|Acute illness within 2 weeks of enrollment
EXCL02|EXCLUSION|Received another vaccine within 30 days of vaccination
EXCL03|EXCLUSION|Positive pregnancy test
;
run;

proc sql noprint;
  select min(rficdtc), max(rfpendtc), strip(put(sum(not missing(armcd)), 8.))
  into :sdt trimmed, :edt trimmed, :nrand trimmed
  from sdtm.dm;
quit;

data ts0;
  length tsparmcd tsparm tsval tsvalcd $200;
  infile datalines dlm='|' truncover;
  input tsparmcd tsparm tsval tsvalcd;
datalines;
TITLE|Trial Title|Synthetic Study of an Influenza Vaccine in Healthy Adults|
SPONSOR|Clinical Study Sponsor|Synthetic Sponsor|
STYPE|Study Type|INTERVENTIONAL|C98388
TPHASE|Trial Phase Classification|PHASE II/III TRIAL|C15694
TTYPE|Trial Type|SAFETY|C49667
TTYPE|Trial Type|IMMUNOGENICITY|C120842
TBLIND|Trial Blinding Schema|DOUBLE BLIND|C15228
TCNTRL|Control Type|PLACEBO|C49648
INTMODEL|Intervention Model|PARALLEL|C82639
RANDOM|Trial is Randomized|Y|C49488
NARMS|Planned Number of Arms|2|
AGEMIN|Planned Minimum Age of Subjects|P18Y|
AGEMAX|Planned Maximum Age of Subjects|P60Y|
SEXPOP|Sex of Participants|BOTH|C49636
PLANSUB|Planned Number of Subjects|240|
INDIC|Trial Disease/Condition Indication|Influenza|
TRT|Investigational Therapy or Treatment|VAXF-101|
DOSE|Dose per Administration|0.5|
DOSU|Dose Units|mL|C28254
DOSFRM|Dose Form|INJECTION|C42946
DOSFRQ|Dosing Frequency|ONCE|C64576
ROUTE|Route of Administration|INTRAMUSCULAR|C28161
LENGTH|Trial Length|P91D|
STRATFCT|Stratification Factor|AGE GROUP|
TINDTP|Trial Intent Type|PREVENTION|C49657
SDTIGVER|SDTM IG Version|3.4|
SDTMVER|SDTM Version|2.0|
;
run;

/* values taken from DM */
data ts1;
  set ts0 end=_last;
  output;
  if _last then do;
    tsparmcd = 'SSTDTC'; tsparm = 'Study Start Date'; tsval = "&sdt"; tsvalcd = ''; output;
    tsparmcd = 'SENDTC'; tsparm = 'Study End Date'; tsval = "&edt"; tsvalcd = ''; output;
    tsparmcd = 'ACTSUB'; tsparm = 'Actual Number of Subjects'; tsval = "&nrand"; tsvalcd = ''; output;
  end;
run;

proc sort data=ts1;
  by tsparmcd;
run;

data ts2;
  length studyid domain tsvcdref tsvcdver tsgrpid tsvalnf $200;
  set ts1;
  by tsparmcd;
  studyid = 'VAXF101';
  domain = 'TS';
  if first.tsparmcd then tsseq = 0;
  tsseq + 1;
  if not missing(tsvalcd) then do;
    tsvcdref = 'CDISC CT';
    tsvcdver = '2026-09-25';
  end;
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    tsseq    = 'Sequence Number'
    tsparmcd = 'Trial Summary Parameter Short Name'
    tsparm   = 'Trial Summary Parameter'
    tsval    = 'Parameter Value'
    tsvalnf  = 'Parameter Value Null Flavor'
    tsvalcd  = 'Parameter Value Code'
    tsvcdref = 'Name of the Reference Terminology'
    tsvcdver = 'Version of the Reference Terminology';
run;

%finalize(ta, ta, Trial Arms,
  vars=STUDYID DOMAIN ARMCD ARM TAETORD ETCD ELEMENT TABRANCH TATRANS EPOCH,
  keys=STUDYID ARMCD TAETORD)

%finalize(te, te, Trial Elements,
  vars=STUDYID DOMAIN ETCD ELEMENT TESTRL TEENRL TEDUR,
  keys=STUDYID ETCD)

%finalize(tv, tv, Trial Visits,
  vars=STUDYID DOMAIN VISITNUM VISIT VISITDY ARMCD ARM TVSTRL TVENRL,
  keys=STUDYID ARMCD VISITNUM)

%finalize(ti, ti, Trial Inclusion/Exclusion Criteria,
  vars=STUDYID DOMAIN IETESTCD IETEST IECAT TIVERS,
  keys=STUDYID IETESTCD)

%finalize(ts2, ts, Trial Summary,
  vars=STUDYID DOMAIN TSSEQ TSPARMCD TSPARM TSVAL TSVALNF TSVALCD TSVCDREF TSVCDVER,
  keys=STUDYID TSPARMCD TSSEQ)
