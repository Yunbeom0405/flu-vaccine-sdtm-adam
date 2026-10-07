# Program : ex.R
# Purpose : Independent QC program for SDTM EX
# Run from the P3 project root after dm.R

source("r/sdtm/setup.R")

trt <- read_raw("RAND") |> select(SUBJECT, TRTCODE)

ex <- read_raw("EX") |>
  filter(DOSED == "Y") |>
  left_join(trt, by = "SUBJECT") |>
  mutate(
    STUDYID = "VAXF101",
    DOMAIN = "EX",
    USUBJID = paste0("VAXF101-", SUBJECT),
    EXTRT = unname(c(A = "VAXF-101", B = "PLACEBO")[TRTCODE]),
    EXCAT = "STUDY VACCINE",
    EXDOSE = as.numeric(EXDOSE),
    EXDOSU = EXDOSEU,
    EXDOSFRM = "INJECTION",
    EXDOSFRQ = "ONCE",
    EXROUTE = toupper(EXROUTE),
    EXLOT = LOTNUM,
    EXLOC = if_else(toupper(EXLOC) == "DELTOID", "DELTOID MUSCLE", toupper(EXLOC)),
    EXLAT = toupper(EXSIDE),
    EXSTDTC = iso_dt(EXDAT, EXTIM),
    EXENDTC = EXSTDTC) |>
  left_join(dm_ref(), by = "USUBJID") |>
  mutate(
    EPOCH = epoch(EXSTDTC, RFXSTDTC),
    EXSTDY = study_day(EXSTDTC, RFSTDTC),
    EXENDY = study_day(EXENDTC, RFSTDTC)) |>
  add_seq("EXSEQ", c("EXTRT", "EXSTDTC"))

finalize(ex, "EX", "Exposure")
