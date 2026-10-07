# Program : td.R
# Purpose : Independent QC program for SDTM TA, TE, TV, TI, TS
# Run from the P3 project root after dm.R

source("r/sdtm/setup.R")

arms <- tribble(
  ~ARMCD, ~ARM,
  "VAXF", "VAXF-101 0.5 mL",
  "PBO", "Placebo")

ta <- tribble(
  ~ARMCD, ~TAETORD, ~ETCD, ~ELEMENT, ~EPOCH,
  "VAXF", 1, "SCRN", "Screening", "SCREENING",
  "VAXF", 2, "VAX", "Vaccination VAXF-101", "TREATMENT",
  "VAXF", 3, "FUP", "Follow-up", "FOLLOW-UP",
  "PBO", 1, "SCRN", "Screening", "SCREENING",
  "PBO", 2, "PBO", "Vaccination Placebo", "TREATMENT",
  "PBO", 3, "FUP", "Follow-up", "FOLLOW-UP") |>
  left_join(arms, by = "ARMCD") |>
  mutate(STUDYID = "VAXF101", DOMAIN = "TA", TABRANCH = NA_character_, TATRANS = NA_character_)

te <- tribble(
  ~ETCD, ~ELEMENT, ~TESTRL, ~TEENRL, ~TEDUR,
  "SCRN", "Screening", "Informed consent", "Randomization", "P14D",
  "VAX", "Vaccination VAXF-101", "Vaccination with VAXF-101", "End of Day 1", "P1D",
  "PBO", "Vaccination Placebo", "Vaccination with placebo", "End of Day 1", "P1D",
  "FUP", "Follow-up", "Day 2", "Day 91 visit", "P90D") |>
  mutate(STUDYID = "VAXF101", DOMAIN = "TE")

visits <- tribble(
  ~VISITNUM, ~VISIT, ~VISITDY, ~TVSTRL,
  1, "SCREENING", NA, "Up to 14 days before vaccination",
  2, "DAY 1", 1, "Vaccination day",
  3, "DAY 8", 8, "7 days after vaccination, +2 days",
  4, "DAY 22", 22, "21 days after vaccination, +/-3 days",
  5, "DAY 91", 91, "90 days after vaccination, +/-7 days")

tv <- cross_join(arms, visits) |>
  mutate(STUDYID = "VAXF101", DOMAIN = "TV", TVENRL = NA_character_)

ti <- tribble(
  ~IETESTCD, ~IECAT, ~IETEST,
  "INCL01", "INCLUSION", "Aged 18 through 60 years at screening",
  "INCL02", "INCLUSION", "Healthy and medically stable",
  "INCL03", "INCLUSION", "Able to attend all scheduled visits and comply with study procedures",
  "EXCL01", "EXCLUSION", "Acute illness within 2 weeks of enrollment",
  "EXCL02", "EXCLUSION", "Received another vaccine within 30 days of vaccination",
  "EXCL03", "EXCLUSION", "Positive pregnancy test") |>
  mutate(STUDYID = "VAXF101", DOMAIN = "TI", TIVERS = "1")

# dates and counts come from the R DM
dm <- read_xpt(file.path(out_dir, "dm.xpt")) |>
  mutate(across(where(is.character), \(x) na_if(x, "")))

ts <- tribble(
  ~TSPARMCD, ~TSPARM, ~TSVAL, ~TSVALCD,
  "TITLE", "Trial Title", "Synthetic Study of an Influenza Vaccine in Healthy Adults", NA,
  "SPONSOR", "Clinical Study Sponsor", "Synthetic Sponsor", NA,
  "STYPE", "Study Type", "INTERVENTIONAL", "C98388",
  "TPHASE", "Trial Phase Classification", "PHASE II/III TRIAL", "C15694",
  "TTYPE", "Trial Type", "SAFETY", "C49667",
  "TTYPE", "Trial Type", "IMMUNOGENICITY", "C120842",
  "TBLIND", "Trial Blinding Schema", "DOUBLE BLIND", "C15228",
  "TCNTRL", "Control Type", "PLACEBO", "C49648",
  "INTMODEL", "Intervention Model", "PARALLEL", "C82639",
  "RANDOM", "Trial is Randomized", "Y", "C49488",
  "NARMS", "Planned Number of Arms", "2", NA,
  "AGEMIN", "Planned Minimum Age of Subjects", "P18Y", NA,
  "AGEMAX", "Planned Maximum Age of Subjects", "P60Y", NA,
  "SEXPOP", "Sex of Participants", "BOTH", "C49636",
  "PLANSUB", "Planned Number of Subjects", "240", NA,
  "INDIC", "Trial Disease/Condition Indication", "Influenza", NA,
  "TRT", "Investigational Therapy or Treatment", "VAXF-101", NA,
  "DOSE", "Dose per Administration", "0.5", NA,
  "DOSU", "Dose Units", "mL", "C28254",
  "DOSFRM", "Dose Form", "INJECTION", "C42946",
  "DOSFRQ", "Dosing Frequency", "ONCE", "C64576",
  "ROUTE", "Route of Administration", "INTRAMUSCULAR", "C28161",
  "LENGTH", "Trial Length", "P91D", NA,
  "STRATFCT", "Stratification Factor", "AGE GROUP", NA,
  "TINDTP", "Trial Intent Type", "PREVENTION", "C49657",
  "SDTIGVER", "SDTM IG Version", "3.4", NA,
  "SDTMVER", "SDTM Version", "2.0", NA) |>
  bind_rows(tribble(
    ~TSPARMCD, ~TSPARM, ~TSVAL,
    "SSTDTC", "Study Start Date", min(dm$RFICDTC),
    "SENDTC", "Study End Date", max(dm$RFPENDTC, na.rm = TRUE),
    "ACTSUB", "Actual Number of Subjects", as.character(sum(!is.na(dm$ARMCD))))) |>
  arrange(TSPARMCD) |>
  group_by(TSPARMCD) |>
  mutate(TSSEQ = row_number()) |>
  ungroup() |>
  mutate(
    STUDYID = "VAXF101",
    DOMAIN = "TS",
    TSVALNF = NA_character_,
    TSVCDREF = if_else(!is.na(TSVALCD), "CDISC CT", NA_character_),
    TSVCDVER = if_else(!is.na(TSVALCD), "2026-09-25", NA_character_))

finalize(ta, "TA", "Trial Arms")
finalize(te, "TE", "Trial Elements")
finalize(tv, "TV", "Trial Visits")
finalize(ti, "TI", "Trial Inclusion/Exclusion Criteria")
finalize(ts, "TS", "Trial Summary")
