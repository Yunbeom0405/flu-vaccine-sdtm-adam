# Program : face.R
# Purpose : Independent QC program for SDTM FACE (domain FA)
# Run from the P3 project root after dm.R

source("r/sdtm/setup.R")

sev_cols <- c("PAIN", "TENDERNESS", "CHILLS", "MALAISE", "MYALGIA", "HEADACHE",
  "ARTHRALGIA", "NAUSEA", "VOMITING")
mm_cols <- c("REDNESS_MM", "SWELLING_MM", "INDURATION_MM")
local <- c("PAIN", "TENDERNESS", "REDNESS", "SWELLING", "INDURATION")

diary <- read_raw("DIARY") |>
  mutate(FATPT = paste("DAY", DIARYDAY), FATPTNUM = as.integer(DIARYDAY),
    FADTC = iso_date(DIARYDAT))
obs <- read_raw("OBS30") |>
  mutate(FATPT = "30 MINUTES POST-DOSE", FATPTNUM = 0L, FADTC = iso_date(OBSDAT))
base <- bind_rows(diary, obs) |>
  mutate(USUBJID = paste0("VAXF101-", SUBJECT))

sev <- base |>
  tidyr::pivot_longer(all_of(sev_cols), names_to = "FAOBJ", values_to = "raw") |>
  filter(!is.na(raw)) |>
  mutate(occur = if_else(toupper(raw) == "NONE", "N", "Y"))
sev_rows <- bind_rows(
  sev |> mutate(FATESTCD = "OCCUR", FAORRES = occur),
  sev |> filter(occur == "Y") |> mutate(FATESTCD = "SEV", FAORRES = toupper(raw)))

mm_rows <- base |>
  tidyr::pivot_longer(all_of(mm_cols), names_to = "FAOBJ", values_to = "FAORRES") |>
  filter(!is.na(FAORRES)) |>
  mutate(FAOBJ = sub("_MM$", "", FAOBJ), FATESTCD = "DIAMETER", FAORRESU = "mm")

fa <- bind_rows(sev_rows, mm_rows) |>
  mutate(
    STUDYID = "VAXF101",
    DOMAIN = "FA",
    FAGRPID = paste0("VACCINATION 1-", FAOBJ),
    FATEST = unname(c(OCCUR = "Occurrence Indicator", SEV = "Severity/Intensity",
      DIAMETER = "Diameter")[FATESTCD]),
    FACAT = "REACTOGENICITY",
    FASCAT = if_else(FAOBJ %in% local, "LOCAL", "SYSTEMIC"),
    FASTRESC = FAORRES,
    FASTRESN = if_else(FATESTCD == "DIAMETER", suppressWarnings(as.numeric(FAORRES)), NA_real_),
    FASTRESU = FAORRESU,
    FAEVAL = "STUDY SUBJECT",
    FATPTREF = "VACCINATION") |>
  left_join(dm_ref(), by = "USUBJID") |>
  mutate(
    FARFTDTC = RFXSTDTC,
    EPOCH = epoch(FADTC, RFXSTDTC),
    FADY = study_day(FADTC, RFSTDTC)) |>
  add_seq("FASEQ", c("FAOBJ", "FATESTCD", "FATPTNUM"))

finalize(fa, "FA", "Findings About Events or Interventions", name = "FACE")
