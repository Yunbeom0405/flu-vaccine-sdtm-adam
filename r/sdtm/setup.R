# Program : setup.R
# Purpose : Packages, paths, shared helpers for the R SDTM programs
# Run from the P3 project root, e.g. source("r/sdtm/dm.R")

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
  library(haven)
})

raw_dir <- "data/raw"
out_dir <- "data/derived/sdtm-r"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

spec_vars <- read_excel("specs/sdtm-spec.xlsx", sheet = "Variables")

# read raw csv as character, blank is NA
read_raw <- function(name) {
  read.csv(file.path(raw_dir, paste0(name, ".csv")),
    colClasses = "character", na.strings = "") |> as_tibble()
}

# DD-MON-YYYY to ISO 8601, unknown day (UN-MON-YYYY) gives yyyy-mm
iso_date <- function(x) {
  m <- match(substr(x, 4, 6), toupper(month.abb))
  case_when(
    is.na(x) ~ NA_character_,
    substr(x, 1, 2) == "UN" ~ sprintf("%s-%02d", substr(x, 8, 11), m),
    TRUE ~ sprintf("%s-%02d-%s", substr(x, 8, 11), m, substr(x, 1, 2)))
}

# date and time collected separately
iso_dt <- function(d, t) {
  dtc <- iso_date(d)
  if_else(!is.na(dtc) & !is.na(t), paste0(dtc, "T", t), dtc)
}

# study day, complete dates only
study_day <- function(dtc, ref) {
  ok <- nchar(dtc) >= 10 & nchar(ref) >= 10
  d <- as.integer(as.Date(substr(dtc, 1, 10)) - as.Date(substr(ref, 1, 10)))
  if_else(ok, d + (d >= 0), NA_integer_)
}

# reference dates from the R DM (run dm.R first)
dm_ref <- function() {
  read_xpt(file.path(out_dir, "dm.xpt")) |>
    mutate(across(where(is.character), \(x) na_if(x, ""))) |>
    select(USUBJID, RFSTDTC, RFXSTDTC, RFXENDTC, RFPENDTC)
}

# epoch from the dose date, partial dates stay null
epoch <- function(dtc, rfx) {
  ok <- nchar(dtc) >= 10
  d <- as.Date(substr(dtc, 1, 10))
  r <- as.Date(substr(rfx, 1, 10))
  case_when(
    !ok ~ NA_character_,
    is.na(r) | d < r ~ "SCREENING",
    d == r ~ "TREATMENT",
    TRUE ~ "FOLLOW-UP")
}

# visit name to number, planned day comes from TV
visit_num <- function(x) match(toupper(x), c("SCREENING", "DAY 1", "DAY 8", "DAY 22", "DAY 91"))

# pre-dose records are SCREENING, also on the dose date
pre_epoch <- function(dtc, visitnum, rfx) {
  pre <- visitnum %in% c(1, 2) & !is.na(rfx)
  if_else(pre & nchar(dtc) >= 10, "SCREENING", epoch(dtc, rfx))
}

# flag the last pre-dose record with a result, per subject and by variables
flag_lobx <- function(df, res, by, dtc) {
  df <- mutate(df, .row = row_number())
  hit <- df |>
    filter(VISITNUM %in% c(1, 2), !is.na(RFXSTDTC), !is.na(.data[[res]])) |>
    arrange(USUBJID, across(all_of(by)), .data[[dtc]], VISITNUM) |>
    group_by(USUBJID, across(all_of(by))) |>
    slice_tail(n = 1) |>
    pull(.row)
  if_else(df$.row %in% hit, "Y", NA_character_)
}

# sequence within subject, ordered by the key variables
add_seq <- function(df, seq, keys) {
  # radix order: ASCII text, missing first, as SAS
  o <- do.call(order, c(list(df$USUBJID), unname(as.list(df[keys])),
    list(na.last = FALSE, method = "radix")))
  df[o, ] |>
    group_by(USUBJID) |>
    mutate("{seq}" := row_number()) |>
    ungroup()
}

# order and label from the spec, write xpt
finalize <- function(df, domain, label, name = domain) {
  sv <- spec_vars |> filter(Dataset == toupper(domain)) |> arrange(Order)
  df <- as.data.frame(df[, sv$Variable])
  for (i in seq_len(nrow(sv))) attr(df[[sv$Variable[i]]], "label") <- sv$Label[i]
  write_xpt(df, file.path(out_dir, paste0(tolower(name), ".xpt")),
    version = 5, name = toupper(name), label = label)
  invisible(df)
}
