# Program : adface.R
# Purpose : Independent QC of ADaM ADFACE, written without reference to the SAS program

source("r/adam/setup.R")

adsl <- read_adam("adsl")
fa <- read_sdtm("face")
vs <- read_sdtm("vs")

params <- tibble(
  FAOBJ = c("PAIN", "TENDERNESS", "REDNESS", "SWELLING", "INDURATION", "FEVER", "CHILLS", "MALAISE", "MYALGIA",
            "HEADACHE", "ARTHRALGIA", "NAUSEA", "VOMITING"),
  PARAMCD = c("PAIN", "TENDERN", "REDNESS", "SWELLING", "INDURAT", "FEVER", "CHILLS", "MALAISE", "MYALGIA",
              "HEADACHE", "ARTHRALG", "NAUSEA", "VOMITING"),
  PARAMN = 1:13,
  PARCAT1 = c(rep("LOCAL", 5), rep("SYSTEMIC", 8))
)
diam_objs <- c("REDNESS", "SWELLING", "INDURATION")

# severity-scale reactions
sev <- fa |> filter(FATESTCD == "SEV") |> select(USUBJID, FAOBJ, FATPT, SEV = FASTRESC, SEVSEQ = FASEQ)
sev_rows <- fa |>
  filter(FATESTCD == "OCCUR", !FAOBJ %in% diam_objs) |>
  left_join(sev, by = c("USUBJID", "FAOBJ", "FATPT")) |>
  mutate(
    AVAL = if_else(FASTRESC == "N", 0, match(SEV, c("MILD", "MODERATE", "SEVERE"))),
    MEASVAL = NA_real_, MEASU = NA_character_,
    SRCDOM = "FA", SRCVAR = "FASTRESC", SRCSEQ = if_else(FASTRESC == "N", FASEQ, SEVSEQ),
    ADT = to_date(FADTC)
  ) |>
  select(USUBJID, FAOBJ, ATPT = FATPT, ADT, AVAL, MEASVAL, MEASU, SRCDOM, SRCVAR, SRCSEQ)

# diameter reactions
dia_rows <- fa |>
  filter(FATESTCD == "DIAMETER") |>
  mutate(
    MEASVAL = FASTRESN,
    AVAL = case_when(MEASVAL < 25 ~ 0, MEASVAL <= 50 ~ 1, MEASVAL <= 100 ~ 2, TRUE ~ 3),
    MEASU = "mm", SRCDOM = "FA", SRCVAR = "FASTRESN", SRCSEQ = FASEQ, ADT = to_date(FADTC)
  ) |>
  select(USUBJID, FAOBJ, ATPT = FATPT, ADT, AVAL, MEASVAL, MEASU, SRCDOM, SRCVAR, SRCSEQ)

# fever from the diary temperature
tmp_rows <- vs |>
  filter(VSTESTCD == "TEMP", VSCAT == "REACTOGENICITY") |>
  mutate(
    FAOBJ = "FEVER",
    MEASVAL = VSSTRESN,
    AVAL = case_when(MEASVAL < 38 ~ 0, MEASVAL < 38.5 ~ 1, MEASVAL < 39 ~ 2, MEASVAL <= 40 ~ 3, TRUE ~ 4),
    MEASU = "C", SRCDOM = "VS", SRCVAR = "VSSTRESN", SRCSEQ = VSSEQ, ADT = to_date(VSDTC)
  ) |>
  select(USUBJID, FAOBJ, ATPT = VSTPT, ADT, AVAL, MEASVAL, MEASU, SRCDOM, SRCVAR, SRCSEQ)

adface <- bind_rows(sev_rows, dia_rows, tmp_rows) |>
  left_join(params, by = "FAOBJ") |>
  mutate(
    PARAM = paste(tools::toTitleCase(tolower(FAOBJ)), "Grade"),
    ATPTN = if_else(ATPT == "30 MINUTES POST-DOSE", 0, suppressWarnings(as.numeric(substr(ATPT, 5, 5))))
  ) |>
  inner_join(select(adsl, USUBJID, STUDYID, TRT01P, TRT01PN, TRT01A, TRT01AN, TRTSDT, AGEGR1, AGEGR1N, SAFFL),
             by = "USUBJID") |>
  mutate(ADY = as.numeric(ADT - TRTSDT) + (ADT >= TRTSDT)) |>
  arrange(USUBJID, PARAMN, ATPTN) |>
  group_by(USUBJID) |>
  mutate(ASEQ = row_number()) |>
  ungroup()

finalize(adface, "adface", c("STUDYID", "USUBJID", "PARAMCD", "ATPTN"))
