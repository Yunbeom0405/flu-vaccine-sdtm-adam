/*******************************************************************************
Program : sv.sas
Purpose : Create SDTM SV
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

/* planned visit number and day come from TV */
proc sql;
  create table sv0 as
  select v.visdat, t.visitnum, t.visit, t.visitdy, d.usubjid, d.rfstdtc
  from raw_visit as v
  left join (select distinct visitnum, visit, visitdy from sdtm.tv) as t
    on upcase(v.visit) = t.visit
  left join sdtm.dm as d on cats('VAXF101-', v.subject) = d.usubjid;
quit;

data sv1;
  length studyid domain svpresp svoccur svstdtc svendtc $200;
  set sv0;

  studyid = 'VAXF101';
  domain = 'SV';
  svpresp = 'Y';
  svoccur = 'Y';
  %iso(visdat, svstdtc)
  svendtc = svstdtc;
  %dy(svstdtc, svstdy)
  %dy(svendtc, svendy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    svpresp  = 'Pre-specified'
    svoccur  = 'Occurrence'
    visitdy  = 'Planned Study Day of Visit'
    svstdtc  = 'Start Date/Time of Observation'
    svendtc  = 'End Date/Time of Observation'
    svstdy   = 'Study Day of Start of Observation'
    svendy   = 'Study Day of End of Observation';
run;

%finalize(sv1, sv, Subject Visits,
  vars=STUDYID DOMAIN USUBJID VISITNUM VISIT SVPRESP SVOCCUR VISITDY SVSTDTC
    SVENDTC SVSTDY SVENDY,
  keys=STUDYID USUBJID VISITNUM)
