# Program : adsl.R
# Purpose : Independent QC of ADaM ADSL, written without reference to the SAS program

source("r/adam/setup.R")

dm <- read_sdtm("dm")
ds <- read_sdtm("ds")
is <- read_sdtm("is")

trtn <- c("VAXF-101 0.5 mL" = 1, "Placebo" = 2)

rand <- ds |> filter(DSDECOD == "RANDOMIZED") |> select(USUBJID, RANDDTC = DSSTDTC)
eos <- ds |> filter(DSCAT == "DISPOSITION EVENT") |> select(USUBJID, EOSDECOD = DSDECOD, EOSDTC = DSSTDTC)

# three strains at Day 1 and Day 22: six valid results, Day 22 sample on study day 19-25
imm <- is |>
  filter(is.na(ISSTAT), !is.na(ISSTRESC), VISITNUM == 2 | (VISITNUM == 4 & ISDY >= 19 & ISDY <= 25)) |>
  count(USUBJID) |>
  filter(n == 6) |>
  transmute(USUBJID, IMMOK = TRUE)

adsl <- dm |>
  left_join(rand, by = "USUBJID") |>
  left_join(eos, by = "USUBJID") |>
  left_join(imm, by = "USUBJID") |>
  mutate(
    TRT01P = ARM,
    TRT01A = ACTARM,
    TRT01PN = unname(trtn[TRT01P]),
    TRT01AN = unname(trtn[TRT01A]),
    AGEGR1 = if_else(AGE <= 45, "18-45", "46-60"),
    AGEGR1N = if_else(AGE <= 45, 1, 2),
    RANDDT = to_date(RANDDTC),
    TRTSDT = to_date(RFXSTDTC),
    TRTSDTM = as.POSIXct(if_else(nchar(RFXSTDTC) >= 16, RFXSTDTC, NA_character_),
                         format = "%Y-%m-%dT%H:%M", tz = "UTC"),
    TRTEDT = to_date(RFXENDTC),
    EOSSTT = if_else(EOSDECOD == "COMPLETED", "COMPLETED", "DISCONTINUED"),
    EOSDT = to_date(EOSDTC),
    DCSREAS = if_else(EOSSTT == "DISCONTINUED", EOSDECOD, NA_character_),
    RANDFL = if_else(!is.na(RANDDT), "Y", "N"),
    SAFFL = if_else(RANDFL == "Y" & !is.na(TRTSDT), "Y", "N"),
    IMMFL = if_else(SAFFL == "Y" & coalesce(IMMOK, FALSE), "Y", "N")
  )

finalize(adsl, "adsl", "USUBJID")
