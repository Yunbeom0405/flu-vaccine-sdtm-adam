# Program : dm.R
# Purpose : Independent QC program for SDTM DM
# Run from the P3 project root

source("r/sdtm/setup.R")

ic <- read_raw("IC")
rand <- read_raw("RAND") |> select(SUBJECT, TRTCODE)

# first dose record per subject
dose <- read_raw("EX") |>
  filter(DOSED == "Y") |>
  transmute(SUBJECT, RFXSTDTC = iso_dt(EXDAT, EXTIM)) |>
  arrange(SUBJECT, RFXSTDTC) |>
  distinct(SUBJECT, .keep_all = TRUE)

end <- read_raw("DS") |> transmute(SUBJECT, RFPENDTC = iso_date(DSDAT))

arm_tab <- tibble(
  TRTCODE = c("A", "B"),
  ARMCD = c("VAXF", "PBO"),
  ARM = c("VAXF-101 0.5 mL", "Placebo"))

# completed years
age_years <- function(birth, ref) {
  b <- as.Date(birth)
  r <- as.Date(ref)
  as.integer(format(r, "%Y")) - as.integer(format(b, "%Y")) -
    (format(r, "%m%d") < format(b, "%m%d"))
}

dm <- read_raw("DM") |>
  left_join(transmute(ic, SUBJECT, RFICDTC = iso_date(ICDAT)), by = "SUBJECT") |>
  left_join(rand, by = "SUBJECT") |>
  left_join(arm_tab, by = "TRTCODE") |>
  left_join(dose, by = "SUBJECT") |>
  left_join(end, by = "SUBJECT") |>
  mutate(
    STUDYID = "VAXF101",
    DOMAIN = "DM",
    USUBJID = paste0("VAXF101-", SUBJECT),
    SUBJID = SUBJECT,
    RFSTDTC = RFXSTDTC,
    RFXENDTC = RFXSTDTC,
    RFENDTC = RFPENDTC,
    SITEID = SITE,
    BRTHDTC = iso_date(BRTHDAT),
    AGE = age_years(BRTHDTC, RFICDTC),
    AGEU = "YEARS",
    SEX = unname(c(MALE = "M", FEMALE = "F")[toupper(SEX)]),
    RACE = toupper(RACE),
    ETHNIC = toupper(ETHNIC),
    ACTARMCD = if_else(is.na(RFXSTDTC), NA_character_, ARMCD),
    ACTARM = if_else(is.na(RFXSTDTC), NA_character_, ARM),
    ARMNRS = case_when(
      is.na(TRTCODE) ~ "SCREEN FAILURE",
      is.na(RFXSTDTC) ~ "ASSIGNED, NOT TREATED"),
    ACTARMUD = NA_character_,
    DTHDTC = NA_character_,
    DTHFL = NA_character_,
    COUNTRY = "USA",
    DMDTC = RFICDTC,
    DMDY = study_day(DMDTC, RFSTDTC))

finalize(dm, "DM", "Demographics")
