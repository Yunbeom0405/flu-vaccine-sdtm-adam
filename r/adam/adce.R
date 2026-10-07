# Program : adce.R
# Purpose : Independent QC of ADaM ADCE, written without reference to the SAS program

source("r/adam/setup.R")

adsl <- read_adam("adsl")
ce <- read_sdtm("ce")

adce <- ce |>
  mutate(
    ATOXGR = case_when(
      CEOCCUR == "N" ~ "0",
      !is.na(CETOXGR) ~ CETOXGR,
      TRUE ~ as.character(match(CESEV, c("MILD", "MODERATE", "SEVERE")))
    ),
    ATOXGRN = as.numeric(ATOXGR),
    ATPT = if_else(CETPT == "30 MINUTES POST-DOSE", CETPT, "WITHIN 7 DAYS POST-DOSE"),
    ATPTN = if_else(CETPT == "30 MINUTES POST-DOSE", 0, 8),
    ASTDT = to_date(CESTDTC),
    AENDT = to_date(CEENDTC)
  ) |>
  inner_join(select(adsl, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, AGEGR1, AGEGR1N, SAFFL),
             by = "USUBJID") |>
  mutate(
    ASTDY = as.numeric(ASTDT - TRTSDT) + (ASTDT >= TRTSDT),
    AENDY = as.numeric(AENDT - TRTSDT) + (AENDT >= TRTSDT)
  )

# first occurrence flags: highest grade first, ties by sequence
occ <- adce |> filter(CEOCCUR == "Y")
f_any <- occ |>
  arrange(USUBJID, ATPTN, desc(ATOXGRN), CESEQ) |>
  group_by(USUBJID, ATPTN) |> slice(1) |> ungroup() |>
  transmute(USUBJID, CEDECOD, ATPTN, AOCCFL = "Y")
f_sub <- occ |>
  arrange(USUBJID, ATPTN, CESCAT, desc(ATOXGRN), CESEQ) |>
  group_by(USUBJID, ATPTN, CESCAT) |> slice(1) |> ungroup() |>
  transmute(USUBJID, CEDECOD, ATPTN, AOCCSFL = "Y")

adce <- adce |>
  left_join(f_any, by = c("USUBJID", "CEDECOD", "ATPTN")) |>
  left_join(f_sub, by = c("USUBJID", "CEDECOD", "ATPTN")) |>
  mutate(AOCCPFL = if_else(CEOCCUR == "Y", "Y", NA_character_))

finalize(adce, "adce", c("STUDYID", "USUBJID", "CEDECOD", "ATPTN"))
