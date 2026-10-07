# Program : vs.R
# Purpose : Independent QC program for SDTM VS
# Run from the P3 project root after dm.R

source("r/sdtm/setup.R")

tests <- c(SYSBP = "Systolic Blood Pressure", DIABP = "Diastolic Blood Pressure",
  PULSE = "Pulse Rate", TEMP = "Temperature")

# visit vitals, one record per test
visit <- read_raw("VITALS") |>
  mutate(VISITNUM = visit_num(VISIT), VISIT = toupper(VISIT), VSDTC = iso_date(VSDAT)) |>
  tidyr::pivot_longer(c(SYSBP, DIABP, PULSE, TEMP), names_to = "VSTESTCD", values_to = "VSORRES") |>
  mutate(
    VSORRESU = case_when(
      VSTESTCD == "TEMP" ~ TEMPU,
      VSTESTCD == "PULSE" ~ "beats/min",
      TRUE ~ "mmHg"),
    VSTPT = NA_character_, VSTPTNUM = NA_integer_, VSCAT = NA_character_, VSSCAT = NA_character_) |>
  select(SUBJECT, VISITNUM, VISIT, VSDTC, VSTESTCD, VSORRES, VSORRESU, VSTPT, VSTPTNUM, VSCAT, VSSCAT)

# diary temperature, reactogenicity
diary <- read_raw("DIARY") |>
  transmute(SUBJECT, VISITNUM = NA_real_, VISIT = NA_character_,
    VSDTC = iso_date(DIARYDAT), VSTESTCD = "TEMP", VSORRES = TEMP, VSORRESU = TEMPU,
    VSTPT = paste("DAY", DIARYDAY), VSTPTNUM = as.integer(DIARYDAY),
    VSCAT = "REACTOGENICITY", VSSCAT = "SYSTEMIC")

# half away from zero, as the SAS ROUND
round1 <- function(x) sign(x) * floor(abs(x) * 10 + 0.5 + 1e-9) / 10

vs <- bind_rows(visit, diary) |>
  mutate(
    STUDYID = "VAXF101",
    DOMAIN = "VS",
    USUBJID = paste0("VAXF101-", SUBJECT),
    VSTEST = unname(tests[VSTESTCD]),
    num = as.numeric(VSORRES),
    VSSTRESN = case_when(
      VSTESTCD != "TEMP" ~ num,
      VSORRESU == "F" ~ round1((num - 32) * 5 / 9),
      TRUE ~ round1(num)),
    VSSTRESU = if_else(VSTESTCD == "TEMP", "C", VSORRESU),
    VSSTRESC = if_else(VSTESTCD == "TEMP", sprintf("%.1f", VSSTRESN), sprintf("%.0f", VSSTRESN)),
    VSSTRESC = if_else(is.na(VSSTRESN), NA_character_, VSSTRESC)) |>
  left_join(dm_ref(), by = "USUBJID") |>
  mutate(
    VSTPTREF = if_else(!is.na(VSTPTNUM), "VACCINATION", NA_character_),
    VSRFTDTC = if_else(!is.na(VSTPTNUM), RFXSTDTC, NA_character_),
    EPOCH = pre_epoch(VSDTC, VISITNUM, RFXSTDTC),
    VSDY = study_day(VSDTC, RFSTDTC),
    VSLOBXFL = flag_lobx(pick(everything()), "VSSTRESN", "VSTESTCD", "VSDTC")) |>
  add_seq("VSSEQ", c("VSTESTCD", "VISITNUM", "VSDTC", "VSTPTNUM"))

finalize(vs, "VS", "Vital Signs")
