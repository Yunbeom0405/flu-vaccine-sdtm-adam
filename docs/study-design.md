# VAXF101 — Study Design

Synthetic study built for portfolio purposes. Not a real trial, and not related to any regulatory submission.
Design elements and calibration numbers are based on publicly posted summary results of a comparable Phase 2/3 seasonal influenza vaccine trial (see README).

## Overview

| Item | Value |
|---|---|
| STUDYID | VAXF101 |
| Product | VAXF-101, trivalent inactivated influenza vaccine (synthetic) |
| Design | Randomized, double-blind, placebo-controlled, parallel group |
| Randomization | 2:1 (VAXF-101 : placebo), stratified by age group (18-45, 46-60) |
| Population | Healthy adults 18-60 years |
| Dosing | Single 0.5 mL IM injection, deltoid, Day 1 |
| Duration | 91 days |

## Arms

| ARMCD | ARM | N |
|---|---|---|
| VAXF | VAXF-101 0.5 mL | 160 |
| PBO | Placebo | 80 |

Total 240 randomized, plus about 10% screen failures (not randomized).
About 3% discontinue early (lost to follow-up, withdrawal by subject). A few randomized subjects are not dosed.

## Schedule

| VISITNUM | VISIT | Study day | Window | Procedures |
|---|---|---|---|---|
| 1 | Screening | -14 to -1 | | Consent, eligibility, demographics, vital signs |
| 2 | Day 1 | 1 | | Randomization, pre-dose blood draw, vaccination, 30-minute observation, diary card issued |
| 3 | Day 8 | 8 | +2 | Diary card review |
| 4 | Day 22 | 22 | +/-3 | Post-dose blood draw, unsolicited AE review |
| 5 | Day 91 | 91 | +/-7 | End of study, SAE review |

## Safety

Solicited reactions are assessed by site staff 30 minutes after vaccination, then recorded by the subject on a diary card daily for 7 days (vaccination day = diary day 1).
Grading follows the FDA 2007 toxicity grading scale for preventive vaccine trials.

| Reaction | Collected as | Grade 1 | Grade 2 | Grade 3 | Grade 4 |
|---|---|---|---|---|---|
| Redness, swelling, induration | Largest diameter (mm) | 25-50 | 51-100 | > 100 | Necrosis |
| Fever | Oral temperature (C) | 38.0-38.4 | 38.5-38.9 | 39.0-40.0 | > 40.0 |
| All other reactions | Severity | Mild | Moderate | Severe | ER visit or hospitalization |

- Local: pain, tenderness, redness, swelling, induration
- Systemic: fever, chills, fatigue/malaise, myalgia, headache, arthralgia, nausea, vomiting
- Diameter and temperature are collected as raw values; the grade is derived in ADaM.
- Unsolicited AEs: Day 1 through Day 22
- SAEs: Day 1 through Day 91

## Immunogenicity

| Item | Value |
|---|---|
| Assay | Hemagglutination inhibition (HAI) |
| Antigens | Strain A (H1N1-like), Strain B (H3N2-like), Strain C (B-lineage) |
| Timepoints | Day 1 (pre-dose), Day 22 |
| Reported values | Reciprocal of twofold dilutions: 10, 20, 40, ..., 5120 |
| Lower limit of quantification (LLOQ) | 10; results below are reported as "<10" |
| Below LLOQ handling | Set to LLOQ/2 = 5 for GMT and GMFR |

## Endpoints

| Type | Endpoint |
|---|---|
| Safety | Number and % of subjects with each solicited local/systemic reaction within 30 minutes and within 7 days, by maximum grade |
| Safety | Number and % of subjects with unsolicited AEs through Day 22, and SAEs through Day 91 |
| Immunogenicity | GMT with 95% CI at Day 1 and Day 22, by strain |
| Immunogenicity | Geometric mean fold rise (GMFR) Day 22 / Day 1 |
| Immunogenicity | Seroconversion: baseline < 10 and Day 22 >= 40, or baseline >= 10 and >= 4-fold rise |
| Immunogenicity | Seroprotection: titer >= 40 |

Subgroups: age group (18-45, 46-60) and baseline serostatus (< 10, >= 10).

## Analysis populations

| Population | Definition |
|---|---|
| Safety | Randomized and dosed, analyzed as treated |
| Immunogenicity (per protocol) | Dosed, valid Day 1 and Day 22 HAI result, Day 22 sample within window |

## Planned domains

| Level | Datasets |
|---|---|
| SDTM | DM, DS, EX, SV, CE, FACE, VS, AE, IS, plus TA, TE, TV, TI, TS |
| ADaM | ADSL, ADIS, ADFACE, ADCE, ADAE |

Out of scope: safety labs, concomitant medications, medical history.

## Calibration

Targets for the data generator, from the public summary results (vaccine N=740, placebo N=148 for safety; 209 and 42 for immunogenicity).

**HAI GMT and seroconversion**

| Strain | Vaccine GMT Day 1 | Vaccine GMT Day 22 | Vaccine GMFR | Vaccine seroconversion | Placebo GMT Day 1 / Day 22 | Placebo seroconversion |
|---|---|---|---|---|---|---|
| A | 9.9 | 130.5 | 13.2 | 70.3% | 13.5 / 13.5 | 0% |
| B | 12.9 | 153.1 | 11.9 | 76.1% | 12.7 / 12.7 | 0% |
| C | 7.2 | 42.0 | 5.9 | 54.1% | 6.4 / 6.8 | 2.4% |

Baseline titers are low (many subjects < 10), so the < 10 rule for seroconversion is exercised.

**Solicited reactions within 7 days (% of subjects, by maximum severity)**

| Reaction | Vaccine any | Vaccine mild / mod / severe | Placebo any | Placebo mild / mod / severe |
|---|---|---|---|---|
| Induration | 3.2% | 3.1 / 0.1 / 0.0 | 0.0% | 0.0 / 0.0 / 0.0 |
| Pain | 62.3% | 54.7 / 7.4 / 0.1 | 17.6% | 16.9 / 0.7 / 0.0 |
| Redness | 2.6% | 2.4 / 0.1 / 0.0 | 0.7% | 0.7 / 0.0 / 0.0 |
| Swelling | 3.5% | 2.7 / 0.8 / 0.0 | 0.7% | 0.7 / 0.0 / 0.0 |
| Tenderness | 67.0% | 59.6 / 7.3 / 0.1 | 21.6% | 20.3 / 1.4 / 0.0 |
| Chills | 6.1% | 4.9 / 1.2 / 0.0 | 8.8% | 6.8 / 1.4 / 0.7 |
| Fatigue/malaise | 19.2% | 15.0 / 3.9 / 0.3 | 18.2% | 12.2 / 5.4 / 0.7 |
| Myalgia | 18.5% | 15.4 / 3.1 / 0.0 | 10.8% | 9.5 / 0.7 / 0.7 |
| Headache | 16.4% | 12.6 / 3.6 / 0.1 | 19.6% | 15.5 / 2.7 / 1.4 |
| Arthralgia | 7.8% | 5.7 / 2.2 / 0.0 | 8.1% | 7.4 / 0.0 / 0.7 |
| Nausea | 2.3% | 1.9 / 0.3 / 0.1 | 3.4% | 2.7 / 0.0 / 0.7 |
| Vomiting | 0.8% | 0.4 / 0.3 / 0.1 | 0.0% | 0.0 / 0.0 / 0.0 |
| Fever (grade 1 / 2 / 3) | 1.5% | 0.7 / 0.7 / 0.1 | 1.4% | 0.7 / 0.7 / 0.0 |

Immediate reactions (within 30 minutes) were rare: pain 3.2% and tenderness 1.9% in the vaccine group, others < 1%.

**Unsolicited AEs and SAEs**: at least one unsolicited AE through Day 21 in 14.9% (vaccine) and 11.5% (placebo); SAEs through Day 91 in 0.5% and 1.4%, none related.

With N=240, events under about 1% may not appear at all. The generator keeps at least a few redness/swelling/induration/fever records so the diameter- and temperature-to-grade derivations have data.
