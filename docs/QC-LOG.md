# QC Log

SAS is the production program, R the independent QC program written from the spec. SDTM and ADaM outputs are compared by key with {diffdf} (`r/adam/compare.R`, `r/sdtm/compare.R`), TLF cells are compared one by one (`r/tlf/compare.R`). Reports are in `output/validation/`.

| Level | Datasets | Result |
|---|---|---|
| SDTM | 15 | Match |
| ADaM | ADSL, ADIS, ADFACE, ADCE, ADAE | Match |
| TLF | Tables 14-1.01, 14-2.01, 14-3.01, 14-3.02 | Match |

## Findings

Each finding was fixed and the affected datasets compared again. None reached a later step uncorrected.

### SDTM

| Finding | Cause |
|---|---|
| `DAY 1` lost its blank in a SAS string built with `cats()` | SAS |
| `--SEQ` order differed from the spec | SAS |
| AE variable order differed from the spec (AECAT before AEBODSYS) | SAS and R |
| Dropout date of one subject group fell after the last visit | Raw data generator |

### ADaM

| Finding | Cause |
|---|---|
| ADIS: `LLOQ` and the value of `<10` results were missing. A variable name was misspelled (`ISLLOQ`), so SAS read an uninitialized variable | SAS |
| ADSL: `IMMFL` first gave 42 subjects instead of 212. `ISSTRESN` is null for `<10`, so a valid result must be tested on `ISSTRESC` | SAS and R |
| ADFACE: SAS read `sdtm.fa`, the dataset is named `FACE`. ADFACE had 1,595 rows instead of 23,591 | SAS |
| ADSL label `Immunogenicity Per-Protocol Population Flag` is 43 characters, longer than the XPT v5 limit of 40 | Spec |
| Labels of `ASEQ` and `PARCAT1` missing in SAS (set before the variable existed) | SAS |
| `TRTSDTM` display format `DATETIME` in R, `DATETIME20` in SAS | R |

After the first P21 ADaM run (0 errors, 18 warnings) the spec and both programs were changed: ARM, ACTARM and ARMNRS added to ADSL, AESTDTC and AEENDTC added to ADAE, the AOCC flag labels set to the standard labels, and the codelist removed from PARAM (PARAM is the decode, not a coded value). The five datasets were compared again.

### TLF

| Finding | Cause |
|---|---|
| Tables 14-1.01 and 14-3.01: a macro argument containing `=` was read as a keyword parameter | SAS |
| Macro `addrow`: length of `VAL` differed between datasets | SAS |

### Define-XML

| Finding | Cause |
|---|---|
| Value-level where clause `ISSTAT IS NULL` is not a supported form, changed to `ISSTAT NE NOT DONE` | Spec |
| DS: DSDECOD codelist applied to all records, 507 P21 warnings. Split by DSCAT with value-level metadata | Spec |

## Data notes

- AE 101-030 and 101-096 start in the same month as the dose and have a year-month start date only. ASTDT is set to the dose date (ASTDTF = D), so both count as treatment-emergent.
- AE 102-107 ends after the end-of-study date (post-study recovery). Kept on purpose, P21 SD1204.
