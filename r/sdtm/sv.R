# Program : sv.R
# Purpose : Independent QC program for SDTM SV
# Run from the P3 project root after dm.R and td.R

source("r/sdtm/setup.R")

# planned visit number and day come from the R TV
tv <- read_xpt(file.path(out_dir, "tv.xpt")) |>
  distinct(VISITNUM, VISIT, VISITDY)

sv <- read_raw("VISIT") |>
  mutate(VISIT = toupper(VISIT)) |>
  left_join(tv, by = "VISIT") |>
  mutate(
    STUDYID = "VAXF101",
    DOMAIN = "SV",
    USUBJID = paste0("VAXF101-", SUBJECT),
    SVPRESP = "Y",
    SVOCCUR = "Y",
    SVSTDTC = iso_date(VISDAT),
    SVENDTC = SVSTDTC) |>
  left_join(dm_ref(), by = "USUBJID") |>
  mutate(
    SVSTDY = study_day(SVSTDTC, RFSTDTC),
    SVENDY = study_day(SVENDTC, RFSTDTC))

stopifnot(!anyNA(sv$VISITNUM))
finalize(sv, "SV", "Subject Visits")
