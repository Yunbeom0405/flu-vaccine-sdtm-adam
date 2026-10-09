/*******************************************************************************
Program : dm.sas
Purpose : Create SDTM DM
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

proc sql;
  create table dm0 as
  select d.*, i.icdat, r.randdat, r.trtcode, x.exdat, x.extim, s.dsdat
  from raw_dm as d
  left join raw_ic as i on d.subject = i.subject
  left join raw_rand as r on d.subject = r.subject
  left join raw_ex(where=(dosed = 'Y')) as x on d.subject = x.subject
  left join raw_ds as s on d.subject = s.subject;
quit;

data dm1;
  set dm0;
  length studyid domain usubjid subjid rfstdtc rfendtc rfxstdtc rfxendtc rficdtc
    rfpendtc dthdtc dthfl siteid brthdtc ageu armcd arm actarmcd actarm armnrs actarmud
    country dmdtc $200;

  studyid = 'VAXF101';
  domain = 'DM';
  usubjid = cats('VAXF101-', subject);
  subjid = subject;
  siteid = site;
  country = 'USA';

  %isodt(exdat, extim, rfxstdtc)
  rfstdtc = rfxstdtc;
  rfxendtc = rfxstdtc;
  %iso(dsdat, rfendtc)
  rfpendtc = rfendtc;
  %iso(icdat, rficdtc)
  dmdtc = rficdtc;
  %dy(dmdtc, dmdy)

  %iso(brthdat, brthdtc)
  age = floor(yrdif(input(brthdtc, e8601da.), input(rficdtc, e8601da.), 'AGE'));
  ageu = 'YEARS';

  sex = substr(upcase(sex), 1, 1);
  race = upcase(race);
  ethnic = upcase(ethnic);

  if missing(trtcode) then armnrs = 'SCREEN FAILURE';
  else do;
    armcd = put(trtcode, $armcd.);
    arm = put(trtcode, $arm.);
    if missing(exdat) then armnrs = 'ASSIGNED, NOT TREATED';
    else do;
      actarmcd = armcd;
      actarm = arm;
    end;
  end;
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    subjid   = 'Subject Identifier for the Study'
    rfstdtc  = 'Subject Reference Start Date/Time'
    rfendtc  = 'Subject Reference End Date/Time'
    rfxstdtc = 'Date/Time of First Study Treatment'
    rfxendtc = 'Date/Time of Last Study Treatment'
    rficdtc  = 'Date/Time of Informed Consent'
    rfpendtc = 'Date/Time of End of Participation'
    siteid   = 'Study Site Identifier'
    brthdtc  = 'Date/Time of Birth'
    age      = 'Age'
    ageu     = 'Age Units'
    sex      = 'Sex'
    race     = 'Race'
    ethnic   = 'Ethnicity'
    armcd    = 'Planned Arm Code'
    arm      = 'Description of Planned Arm'
    actarmcd = 'Actual Arm Code'
    actarm   = 'Description of Actual Arm'
    armnrs   = 'Reason Arm and/or Actual Arm is Null'
    actarmud = 'Description of Unplanned Actual Arm'
    dthdtc   = 'Date/Time of Death'
    dthfl    = 'Subject Death Flag'
    country  = 'Country'
    dmdtc    = 'Date/Time of Collection'
    dmdy     = 'Study Day of Collection';
run;

%finalize(dm1, dm, Demographics,
  vars=STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC RFXSTDTC RFXENDTC RFICDTC
    RFPENDTC DTHDTC DTHFL SITEID BRTHDTC AGE AGEU SEX RACE ETHNIC ARMCD ARM ACTARMCD
    ACTARM ARMNRS ACTARMUD COUNTRY DMDTC DMDY,
  keys=STUDYID USUBJID)
