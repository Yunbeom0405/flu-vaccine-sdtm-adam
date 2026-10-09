# Program : is.R
# Purpose : Independent QC program for SDTM IS
# Run from the P3 project root after dm.R

source("r/sdtm/setup.R")

is_ <- read_raw("LB_HAI") |>
  mutate(
    STUDYID = "VAXF101",
    DOMAIN = "IS",
    USUBJID = paste0("VAXF101-", SUBJECT),
    ISTESTCD = "MBFAB",
    ISTEST = "Functional Microbial-induced Antibody",
    ISBDAGNT = toupper(sub("^HAI ", "", ANALYTE, ignore.case = TRUE)),
    ISCAT = "IMMUNOGENICITY",
    ISSPEC = "SERUM",
    ISMETHOD = "HEMAGGLUTINATION INHIBITION ASSAY",
    ISORNRLO = NA_character_, ISORNRHI = NA_character_, ISNRIND = NA_character_,
    ISSTNRLO = NA_real_, ISSTNRHI = NA_real_,
    ISLLOQ = 10,
    VISITNUM = visit_num(VISIT),
    VISIT = toupper(VISIT),
    ISDTC = COLLDAT,
    done = !is.na(RESULT),
    ISORRES = RESULT,
    ISORRESU = if_else(done, UNIT, NA_character_),
    ISSTRESC = RESULT,
    ISSTRESU = ISORRESU,
    ISSTRESN = if_else(done & RESULT != "<10", suppressWarnings(as.numeric(RESULT)), NA_real_),
    ISSTAT = if_else(done, NA_character_, "NOT DONE"),
    ISREASND = if_else(done, NA_character_, toupper(COMMENT))) |>
  left_join(dm_ref(), by = "USUBJID") |>
  mutate(
    EPOCH = pre_epoch(ISDTC, VISITNUM, RFXSTDTC),
    ISDY = study_day(ISDTC, RFSTDTC),
    ISLOBXFL = flag_lobx(pick(everything()), "ISSTRESC", "ISBDAGNT", "ISDTC")) |>
  add_seq("ISSEQ", c("ISTESTCD", "ISBDAGNT", "VISITNUM"))

finalize(is_, "IS", "Immunogenicity Specimen Assessments")
