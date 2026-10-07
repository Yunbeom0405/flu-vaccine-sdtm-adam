# Program : ce.R
# Purpose : Independent QC program for SDTM CE
# Run from the P3 project root after dm.R and vs.R

source("r/sdtm/setup.R")

sev_cols <- c("PAIN", "TENDERNESS", "CHILLS", "MALAISE", "MYALGIA", "HEADACHE",
  "ARTHRALGIA", "NAUSEA", "VOMITING")
mm_cols <- c("REDNESS_MM", "SWELLING_MM", "INDURATION_MM")
local <- c("PAIN", "TENDERNESS", "REDNESS", "SWELLING", "INDURATION")

# grade per reaction and day: severity scale 0-3, diameter and temperature toxicity scale
grades <- function(raw, window, date_col) {
  raw <- mutate(raw, dtc = iso_date(.data[[date_col]]))
  sev <- raw |>
    tidyr::pivot_longer(all_of(sev_cols), names_to = "CETERM", values_to = "v") |>
    filter(!is.na(v)) |>
    mutate(kind = "SEV", grade = match(toupper(v), c("NONE", "MILD", "MODERATE", "SEVERE")) - 1)
  mm <- raw |>
    tidyr::pivot_longer(all_of(mm_cols), names_to = "CETERM", values_to = "v") |>
    filter(!is.na(v)) |>
    mutate(CETERM = sub("_MM$", "", CETERM), kind = "TOX",
      grade = (as.numeric(v) >= 25) + (as.numeric(v) > 50) + (as.numeric(v) > 100))
  bind_rows(sev, mm) |>
    transmute(USUBJID = paste0("VAXF101-", SUBJECT), CETERM, kind, window = window, dtc, grade)
}

fever <- read_xpt(file.path(out_dir, "vs.xpt")) |>
  filter(VSTESTCD == "TEMP", VSSCAT == "SYSTEMIC") |>
  transmute(USUBJID, CETERM = "FEVER", kind = "TOX", window = 7, dtc = VSDTC,
    grade = (VSSTRESN >= 38) + (VSSTRESN >= 38.5) + (VSSTRESN >= 39) + (VSSTRESN > 40))

gr <- bind_rows(
  grades(read_raw("DIARY"), 7, "DIARYDAT"),
  grades(read_raw("OBS30"), 0, "OBSDAT"),
  fever) |>
  mutate(dnum = as.Date(if_else(nchar(dtc) >= 10, dtc, NA_character_)))

first_last <- function(x, g) {
  x <- x[g >= 1 & !is.na(x)]
  c(if (length(x)) min(x) else NA, if (length(x)) max(x) else NA)
}

ce <- gr |>
  group_by(USUBJID, CETERM, kind, window) |>
  summarise(maxgr = max(grade),
    d1 = as.Date(suppressWarnings(min(dnum[grade >= 1], na.rm = TRUE))),
    d2 = as.Date(suppressWarnings(max(dnum[grade >= 1], na.rm = TRUE))),
    .groups = "drop") |>
  mutate(
    across(c(d1, d2), \(d) as.Date(if_else(is.finite(as.numeric(d)), d, NA))),
    STUDYID = "VAXF101",
    DOMAIN = "CE",
    CEGRPID = paste0("VACCINATION 1-", CETERM),
    CEDECOD = CETERM,
    CECAT = "REACTOGENICITY",
    CESCAT = if_else(CETERM %in% local, "LOCAL", "SYSTEMIC"),
    CEPRESP = "Y",
    CEOCCUR = if_else(maxgr >= 1, "Y", "N"),
    CESEV = if_else(kind == "SEV" & maxgr >= 1,
      c("MILD", "MODERATE", "SEVERE")[pmax(maxgr, 1)], NA_character_),
    CETOXGR = if_else(kind == "TOX" & maxgr >= 1, as.character(maxgr), NA_character_),
    CESTDTC = if_else(maxgr >= 1, format(d1), NA_character_),
    CEENDTC = if_else(maxgr >= 1, format(d2), NA_character_),
    CETPT = if_else(window == 0, "30 MINUTES POST-DOSE", "DAY 7"),
    CETPTNUM = as.integer(window),
    CEEVINTX = if_else(window == 0, "WITHIN 30 MINUTES AFTER VACCINATION",
      "WITHIN 7 DAYS AFTER VACCINATION"),
    CETPTREF = "VACCINATION") |>
  left_join(dm_ref(), by = "USUBJID") |>
  mutate(
    CERFTDTC = RFXSTDTC,
    EPOCH = epoch(coalesce(CESTDTC, substr(RFXSTDTC, 1, 10)), RFXSTDTC),
    CESTDY = study_day(CESTDTC, RFSTDTC),
    CEENDY = study_day(CEENDTC, RFSTDTC)) |>
  add_seq("CESEQ", c("CEDECOD", "CETPTNUM"))

finalize(ce, "CE", "Clinical Events")
