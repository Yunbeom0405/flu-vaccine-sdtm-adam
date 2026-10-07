# Program : ie.R
# Purpose : Independent QC program for SDTM IE
# Run from the P3 project root after dm.R and td.R

source("r/sdtm/setup.R")

crit <- c(
  "ACUTE ILLNESS WITHIN 2 WEEKS OF ENROLLMENT" = "EXCL01",
  "RECEIVED ANOTHER VACCINE WITHIN 30 DAYS" = "EXCL02",
  "POSITIVE PREGNANCY TEST" = "EXCL03",
  "MEDICAL CONDITION NOT STABLE" = "INCL02",
  "UNABLE TO ATTEND ALL SCHEDULED VISITS" = "INCL03")

ti <- read_xpt(file.path(out_dir, "ti.xpt")) |>
  select(IETESTCD, IETEST, IECAT)

ie <- read_raw("IE") |>
  filter(ELIGIBLE == "N") |>
  mutate(IETESTCD = unname(crit[toupper(IETERM)])) |>
  left_join(ti, by = "IETESTCD") |>
  mutate(
    STUDYID = "VAXF101",
    DOMAIN = "IE",
    USUBJID = paste0("VAXF101-", SUBJECT),
    IEORRES = if_else(IECAT == "EXCLUSION", "Y", "N"),
    IESTRESC = IEORRES,
    VISITNUM = 1,
    VISIT = "SCREENING",
    EPOCH = "SCREENING",
    IEDTC = iso_date(IEDAT)) |>
  left_join(dm_ref(), by = "USUBJID") |>
  mutate(IEDY = study_day(IEDTC, RFSTDTC)) |>
  add_seq("IESEQ", "IETESTCD")

stopifnot(!anyNA(ie$IECAT))
finalize(ie, "IE", "Inclusion/Exclusion Criterion Not Met")
