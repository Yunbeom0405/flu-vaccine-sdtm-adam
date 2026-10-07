# Program : adae.R
# Purpose : Independent QC of ADaM ADAE, written without reference to the SAS program

source("r/adam/setup.R")

adsl <- read_adam("adsl")
ae <- read_sdtm("ae")

adae <- ae |>
  inner_join(select(adsl, USUBJID, TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, AGEGR1, AGEGR1N, SAFFL),
             by = "USUBJID") |>
  mutate(
    AESEVN = match(AESEV, c("MILD", "MODERATE", "SEVERE")),
    AENDT = to_date(AEENDTC),
    # year-month only: dose date if same month, else first of month
    ASTDT = case_when(
      nchar(AESTDTC) >= 10 ~ to_date(AESTDTC),
      nchar(AESTDTC) == 7 & format(TRTSDT, "%Y-%m") == AESTDTC ~ TRTSDT,
      nchar(AESTDTC) == 7 ~ as.Date(paste0(AESTDTC, "-01"))
    ),
    ASTDTF = if_else(nchar(AESTDTC) == 7 & !is.na(TRTSDT), "D", NA_character_),
    ASTDY = as.numeric(ASTDT - TRTSDT) + (ASTDT >= TRTSDT),
    AENDY = as.numeric(AENDT - TRTSDT) + (AENDT >= TRTSDT),
    TRTEMFL = if_else(!is.na(ASTDT) & !is.na(TRTSDT) & ASTDT >= TRTSDT, "Y", NA_character_),
    ANL01FL = if_else(AECAT == "UNSOLICITED" & TRTEMFL %in% "Y" & ASTDY <= 22, "Y", NA_character_),
    ANL02FL = if_else(AESER == "Y" & TRTEMFL %in% "Y" & ASTDY <= 91, "Y", NA_character_)
  )

# first occurrence flags among treatment-emergent records
te <- adae |> filter(TRTEMFL %in% "Y") |> arrange(ASTDT, AESEQ)
flag <- function(grp, name) {
  te |> group_by(across(all_of(grp))) |> slice(1) |> ungroup() |>
    transmute(USUBJID, AESEQ, !!name := "Y")
}
adae <- adae |>
  left_join(flag("USUBJID", "AOCCFL"), by = c("USUBJID", "AESEQ")) |>
  left_join(flag(c("USUBJID", "AEBODSYS"), "AOCCSFL"), by = c("USUBJID", "AESEQ")) |>
  left_join(flag(c("USUBJID", "AEBODSYS", "AEDECOD"), "AOCCPFL"), by = c("USUBJID", "AESEQ"))

finalize(adae, "adae", c("STUDYID", "USUBJID", "AESEQ"))
