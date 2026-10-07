/*******************************************************************************
Program : ie.sas
Purpose : Create SDTM IE
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

proc format;
value $iecode
'ACUTE ILLNESS WITHIN 2 WEEKS OF ENROLLMENT' = 'EXCL01'
'RECEIVED ANOTHER VACCINE WITHIN 30 DAYS' = 'EXCL02'
'POSITIVE PREGNANCY TEST' = 'EXCL03'
'MEDICAL CONDITION NOT STABLE' = 'INCL02'
'UNABLE TO ATTEND ALL SCHEDULED VISITS' = 'INCL03';
run;

/* screen failures only; criterion text comes from TI */
proc sql;
  create table ie0 as
  select a.subject, a.iedat, a.ietestcd, t.ietest, t.iecat, d.usubjid, d.rfstdtc
  from (select subject, iedat, put(upcase(ieterm), $iecode.) as ietestcd
        from raw_ie where eligible = 'N') as a
  left join sdtm.ti as t on a.ietestcd = t.ietestcd
  left join sdtm.dm as d on cats('VAXF101-', a.subject) = d.usubjid
  order by d.usubjid, a.ietestcd;
quit;

data ie1;
  length studyid domain ieorres iestresc visit epoch iedtc $200;
  set ie0;
  by usubjid;

  studyid = 'VAXF101';
  domain = 'IE';
  if first.usubjid then ieseq = 0;
  ieseq + 1;
  if missing(iecat) then put 'WARN' "ING: unmapped criterion " subject= ietestcd=;
  ieorres = ifc(iecat = 'EXCLUSION', 'Y', 'N');
  iestresc = ieorres;
  visitnum = 1;
  visit = 'SCREENING';
  epoch = 'SCREENING';
  %iso(iedat, iedtc)
  %dy(iedtc, iedy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    ieseq    = 'Sequence Number'
    ietestcd = 'Inclusion/Exclusion Criterion Short Name'
    ietest   = 'Inclusion/Exclusion Criterion'
    iecat    = 'Inclusion/Exclusion Category'
    ieorres  = 'I/E Criterion Original Result'
    iestresc = 'I/E Criterion Result in Std Format'
    visitnum = 'Visit Number'
    visit    = 'Visit Name'
    epoch    = 'Epoch'
    iedtc    = 'Date/Time of Collection'
    iedy     = 'Study Day of Collection';
run;

%finalize(ie1, ie, Inclusion/Exclusion Criterion Not Met,
  vars=STUDYID DOMAIN USUBJID IESEQ IETESTCD IETEST IECAT IEORRES IESTRESC
    VISITNUM VISIT EPOCH IEDTC IEDY,
  keys=STUDYID USUBJID IETESTCD)
