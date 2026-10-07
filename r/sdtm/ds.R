# Program : ds.R
# Purpose : Independent QC program for SDTM DS
# Run from the P3 project root after dm.R

source("r/sdtm/setup.R")

milestone <- bind_rows(
  read_raw("IC") |> transmute(SUBJECT, DSTERM = "INFORMED CONSENT OBTAINED",
    DSREFID = NA_character_, DSSTDTC = iso_date(ICDAT)),
  read_raw("RAND") |> transmute(SUBJECT, DSTERM = "RANDOMIZED",
    DSREFID = RANDNUM, DSSTDTC = iso_date(RANDDAT))) |>
  mutate(DSDECOD = DSTERM, DSCAT = "PROTOCOL MILESTONE")

outcome <- c(
  "Completed" = "COMPLETED",
  "Lost to Follow-up" = "LOST TO FOLLOW-UP",
  "Screen Failure" = "SCREEN FAILURE",
  "Withdrawal by Subject" = "WITHDRAWAL BY SUBJECT")

event <- read_raw("DS") |>
  transmute(SUBJECT,
    DSTERM = toupper(DSTERM),
    DSREFID = NA_character_,
    DSSTDTC = iso_date(DSDAT),
    DSDECOD = unname(outcome[read_raw("DS")$DSTERM]),
    DSCAT = "DISPOSITION EVENT")

ds <- bind_rows(milestone, event) |>
  mutate(
    STUDYID = "VAXF101",
    DOMAIN = "DS",
    USUBJID = paste0("VAXF101-", SUBJECT)) |>
  left_join(dm_ref(), by = "USUBJID") |>
  mutate(
    EPOCH = if_else(DSCAT == "PROTOCOL MILESTONE", "SCREENING", epoch(DSSTDTC, RFXSTDTC)),
    DSSTDY = study_day(DSSTDTC, RFSTDTC)) |>
  mutate(ORD = match(DSDECOD, c("INFORMED CONSENT OBTAINED", "RANDOMIZED"), nomatch = 3)) |>
  add_seq("DSSEQ", c("DSSTDTC", "ORD"))

finalize(ds, "DS", "Disposition")
