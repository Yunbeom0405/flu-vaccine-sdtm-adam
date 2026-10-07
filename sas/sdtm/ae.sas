/*******************************************************************************
Program : ae.sas
Purpose : Create SDTM AE
*******************************************************************************/

%include "U:\My SAS Files\Portfolio3\sas\sdtm\setup.sas";

/* local coding table, no MedDRA */
proc format;
value $aept
'RUNNY NOSE' = 'NASOPHARYNGITIS'
'NASAL CONGESTION' = 'NASOPHARYNGITIS'
'COMMON COLD' = 'NASOPHARYNGITIS'
'COLD' = 'NASOPHARYNGITIS'
'COUGH' = 'COUGH'
'SORE THROAT' = 'OROPHARYNGEAL PAIN'
'THROAT PAIN' = 'OROPHARYNGEAL PAIN'
'URTI' = 'UPPER RESPIRATORY TRACT INFECTION'
'UPPER RESPIRATORY INFECTION' = 'UPPER RESPIRATORY TRACT INFECTION'
'DIARRHEA' = 'DIARRHOEA'
'LOOSE STOOLS' = 'DIARRHOEA'
'DIZZY' = 'DIZZINESS'
'DIZZINESS' = 'DIZZINESS'
'BACK PAIN' = 'BACK PAIN'
'LOWER BACK PAIN' = 'BACK PAIN'
'RASH ON ARM' = 'RASH'
'SKIN RASH' = 'RASH'
'INSOMNIA' = 'INSOMNIA'
'TROUBLE SLEEPING' = 'INSOMNIA'
'STOMACH ACHE' = 'ABDOMINAL PAIN'
'ABDOMINAL PAIN' = 'ABDOMINAL PAIN'
'TOOTH ACHE' = 'TOOTHACHE'
'TOOTHACHE' = 'TOOTHACHE'
'APPENDICITIS' = 'APPENDICITIS'
'FALL WITH FRACTURE OF LEFT WRIST' = 'WRIST FRACTURE';
value $aesoc
'NASOPHARYNGITIS' = 'INFECTIONS AND INFESTATIONS'
'UPPER RESPIRATORY TRACT INFECTION' = 'INFECTIONS AND INFESTATIONS'
'APPENDICITIS' = 'INFECTIONS AND INFESTATIONS'
'COUGH' = 'RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS'
'OROPHARYNGEAL PAIN' = 'RESPIRATORY, THORACIC AND MEDIASTINAL DISORDERS'
'DIARRHOEA' = 'GASTROINTESTINAL DISORDERS'
'ABDOMINAL PAIN' = 'GASTROINTESTINAL DISORDERS'
'TOOTHACHE' = 'GASTROINTESTINAL DISORDERS'
'DIZZINESS' = 'NERVOUS SYSTEM DISORDERS'
'BACK PAIN' = 'MUSCULOSKELETAL AND CONNECTIVE TISSUE DISORDERS'
'RASH' = 'SKIN AND SUBCUTANEOUS TISSUE DISORDERS'
'INSOMNIA' = 'PSYCHIATRIC DISORDERS'
'WRIST FRACTURE' = 'INJURY, POISONING AND PROCEDURAL COMPLICATIONS';
value $aeout
'RECOVERED/RESOLVED' = 'RECOVERED/RESOLVED'
'RECOVERING' = 'RECOVERING/RESOLVING';
run;

proc sql;
  create table ae0 as
  select a.*, d.usubjid, d.rfstdtc, d.rfxstdtc, d.rfxendtc, d.rfpendtc
  from raw_ae as a
  left join sdtm.dm as d on cats('VAXF101-', a.subject) = d.usubjid
  order by d.usubjid, a.aestdat, a.aeterm;
quit;

data ae1;
  length studyid domain aedecod aebodsys aecat aeacn aeout aeenrtpt aeentpt epoch
    aestdtc aeendtc $200;
  set ae0(rename=(aeterm=_term aeacn=_acn aeout=_out));

  studyid = 'VAXF101';
  domain = 'AE';
  aeterm = strip(_term);
  aedecod = put(upcase(aeterm), $aept.);
  aebodsys = put(aedecod, $aesoc.);
  if aebodsys = aedecod then put 'WARN' "ING: uncoded AE term " subject= aeterm=;
  aecat = 'UNSOLICITED';

  aesev = upcase(aesev);
  aerel = upcase(aerel);
  aeacn = 'NOT APPLICABLE';
  aeout = put(upcase(_out), $aeout.);

  %iso(aestdat, aestdtc)
  %iso(aeendat, aeendtc)
  if aeongo = 'Y' then do;
    aeenrtpt = 'ONGOING';
    aeentpt = substr(rfpendtc, 1, 10);
  end;
  %epoch(aestdtc)
  %dy(aestdtc, aestdy)
  %dy(aeendtc, aeendy)
  label
    studyid  = 'Study Identifier'
    domain   = 'Domain Abbreviation'
    usubjid  = 'Unique Subject Identifier'
    aeterm   = 'Reported Term for the Adverse Event'
    aedecod  = 'Dictionary-Derived Term'
    aebodsys = 'Body System or Organ Class'
    aecat    = 'Category for Adverse Event'
    aesev    = 'Severity/Intensity'
    aeser    = 'Serious Event'
    aeacn    = 'Action Taken with Study Treatment'
    aerel    = 'Causality'
    aeout    = 'Outcome of Adverse Event'
    aeshosp  = 'Requires or Prolongs Hospitalization'
    epoch    = 'Epoch'
    aestdtc  = 'Start Date/Time of Adverse Event'
    aeendtc  = 'End Date/Time of Adverse Event'
    aestdy   = 'Study Day of Start of Adverse Event'
    aeendy   = 'Study Day of End of Adverse Event'
    aeenrtpt = 'End Relative to Reference Time Point'
    aeentpt  = 'End Reference Time Point';
run;

/* sequence in key order, after the coding */
proc sort data=ae1;
  by usubjid aedecod aestdtc;
run;

data ae1;
  set ae1;
  by usubjid;
  if first.usubjid then aeseq = 0;
  aeseq + 1;
  label aeseq = 'Sequence Number';
run;

%finalize(ae1, ae, Adverse Events,
  vars=STUDYID DOMAIN USUBJID AESEQ AETERM AEDECOD AECAT AEBODSYS AESEV AESER
    AEACN AEREL AEOUT AESHOSP EPOCH AESTDTC AEENDTC AESTDY AEENDY AEENRTPT AEENTPT,
  keys=STUDYID USUBJID AEDECOD AESTDTC AESEQ)
