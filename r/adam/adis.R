# Program : adis.R
# Purpose : Independent QC of ADaM ADIS, written without reference to the SAS program

source("r/adam/setup.R")

adsl <- read_adam("adsl")
is <- read_sdtm("is")

adis <- is |>
  mutate(
    PARAMCD = paste0("HAI", substr(ISBDAGNT, 8, 8)),
    PARAM = paste0("HAI Titer, Strain ", substr(ISBDAGNT, 8, 8)),
    PARAMN = match(substr(ISBDAGNT, 8, 8), c("A", "B", "C")),
    AVALC = ISSTRESC,
    AVAL = case_when(!is.na(ISSTAT) ~ NA_real_, ISSTRESC == "<10" ~ ISLLOQ / 2, TRUE ~ ISSTRESN),
    LLOQ = ISLLOQ,
    ADT = to_date(ISDTC),
    AVISIT = VISIT,
    AVISITN = VISITNUM,
    SRCDOM = "IS",
    SRCVAR = "ISSTRESC",
    SRCSEQ = ISSEQ
  ) |>
  inner_join(select(adsl, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, AGEGR1, AGEGR1N, SAFFL, IMMFL),
             by = "USUBJID")

base <- adis |>
  filter(ISLOBXFL == "Y", !is.na(AVAL)) |>
  select(USUBJID, PARAMCD, BASE = AVAL, BASEC = AVALC)

adis <- adis |>
  left_join(base, by = c("USUBJID", "PARAMCD")) |>
  mutate(
    ADY = as.numeric(ADT - TRTSDT) + (ADT >= TRTSDT),
    ABLFL = if_else(ISLOBXFL %in% "Y" & !is.na(AVAL), "Y", NA_character_),
    BASECAT1 = case_when(is.na(BASEC) ~ NA_character_, BASEC == "<10" ~ "<10", TRUE ~ ">=10"),
    R2BASE = if_else(AVISITN == 4 & !is.na(AVAL) & !is.na(BASE), AVAL / BASE, NA_real_),
    CRIT1 = "Titer >= 40",
    CRIT1FL = case_when(is.na(AVAL) ~ NA_character_, AVAL >= 40 ~ "Y", TRUE ~ "N"),
    CRIT2 = if_else(AVISITN == 4, "Seroconversion", NA_character_),
    CRIT2FL = case_when(
      AVISITN != 4 | is.na(AVAL) | is.na(BASE) ~ NA_character_,
      (BASECAT1 == "<10" & AVAL >= 40) | (BASECAT1 == ">=10" & R2BASE >= 4) ~ "Y",
      TRUE ~ "N"),
    ANL01FL = if_else(IMMFL == "Y" & !is.na(AVAL), "Y", NA_character_),
    PARCAT1 = "HAI"
  ) |>
  arrange(USUBJID, PARAMCD, AVISITN) |>
  group_by(USUBJID) |>
  mutate(ASEQ = row_number()) |>
  ungroup()

finalize(adis, "adis", c("STUDYID", "USUBJID", "PARAMCD", "AVISITN"))
