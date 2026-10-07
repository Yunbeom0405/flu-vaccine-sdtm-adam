/*******************************************************************************
Program : ex.sas
Purpose : Create SDTM EX
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

proc sql;
  create table ex0 as
  select e.*, r.trtcode, d.usubjid, d.rfstdtc, d.rfxstdtc, d.rfxendtc
  from raw_ex as e
  left join raw_rand as r on e.subject = r.subject
  left join sdtm.dm as d on cats('VAXF101-', e.subject) = d.usubjid
  where e.dosed = 'Y';
quit;

data ex1;
  length studyid domain extrt excat exdosu exdosfrm exdosfrq exlot exloc exlat
    exstdtc exendtc epoch $200;
  set ex0(rename=(exdose=_dose exroute=_route exloc=_loc));

  studyid = 'VAXF101';
  domain = 'EX';
  exseq = 1;
  extrt = ifc(trtcode = 'A', 'VAXF-101', 'PLACEBO');
  excat = 'STUDY VACCINE';
  exdose = input(_dose, best12.);
  exdosu = exdoseu;
  exdosfrm = 'INJECTION';
  exdosfrq = 'ONCE';
  exroute = upcase(_route);
  exlot = lotnum;
  exloc = ifc(upcase(_loc) = 'DELTOID', 'DELTOID MUSCLE', upcase(_loc));
  exlat = upcase(exside);

  %isodt(exdat, extim, exstdtc)
  exendtc = exstdtc;
  %epoch(exstdtc)
  %dy(exstdtc, exstdy)
  %dy(exendtc, exendy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    exseq    = 'Sequence Number'
    extrt    = 'Name of Treatment'
    excat    = 'Category of Treatment'
    exdose   = 'Dose'
    exdosu   = 'Dose Units'
    exdosfrm = 'Dose Form'
    exdosfrq = 'Dosing Frequency per Interval'
    exroute  = 'Route of Administration'
    exlot    = 'Lot Number'
    exloc    = 'Location of Dose Administration'
    exlat    = 'Laterality'
    epoch    = 'Epoch'
    exstdtc  = 'Start Date/Time of Treatment'
    exendtc  = 'End Date/Time of Treatment'
    exstdy   = 'Study Day of Start of Treatment'
    exendy   = 'Study Day of End of Treatment';
run;

%finalize(ex1, ex, Exposure,
  vars=STUDYID DOMAIN USUBJID EXSEQ EXTRT EXCAT EXDOSE EXDOSU EXDOSFRM EXDOSFRQ
    EXROUTE EXLOT EXLOC EXLAT EPOCH EXSTDTC EXENDTC EXSTDY EXENDY,
  keys=STUDYID USUBJID EXTRT EXSTDTC)
