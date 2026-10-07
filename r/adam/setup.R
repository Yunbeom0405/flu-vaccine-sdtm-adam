# Program : setup.R
# Purpose : Packages, paths and shared helpers for the R ADaM programs ({admiral})
# Run from the P3 project root, e.g. source("r/adam/adsl.R")

suppressPackageStartupMessages({
  library(admiral)
  library(dplyr)
  library(tidyr)
  library(haven)
  library(readxl)
})

sdtm_dir <- "data/derived/sdtm"
out_dir <- "data/derived/adam-r"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

spec_vars <- read_excel("specs/adam-spec.xlsx", sheet = "Variables")
spec_ds <- read_excel("specs/adam-spec.xlsx", sheet = "Datasets")

# read xpt, blank character values as NA
read_sdtm <- function(domain) {
  read_xpt(file.path(sdtm_dir, paste0(domain, ".xpt"))) |> convert_blanks_to_na()
}

read_adam <- function(ds) {
  read_xpt(file.path(out_dir, paste0(ds, ".xpt"))) |> convert_blanks_to_na()
}

# ISO 8601 text -> Date, date part only
to_date <- function(dtc) {
  as.Date(if_else(!is.na(dtc) & nchar(dtc) >= 10, substr(dtc, 1, 10), NA_character_))
}

# keep/order variables and labels from the spec, check keys, write xpt
finalize <- function(dat, ds, keys) {
  meta <- filter(spec_vars, Dataset == toupper(ds)) |> arrange(Order)
  label <- filter(spec_ds, Dataset == toupper(ds))$Description

  dups <- dat |> count(across(all_of(keys))) |> filter(n > 1)
  if (nrow(dups) > 0) warning("duplicate key in ", ds, ": ", nrow(dups), " key(s)")

  out <- dat |>
    select(all_of(meta$Variable)) |>
    mutate(across(where(is.numeric), as.double)) |>
    arrange(across(all_of(keys)))
  for (i in seq_len(nrow(meta))) attr(out[[meta$Variable[i]]], "label") <- meta$Label[i]
  for (v in names(out)[vapply(out, inherits, logical(1), "Date")]) attr(out[[v]], "format.sas") <- "DATE9"
  for (v in names(out)[vapply(out, inherits, logical(1), "POSIXct")]) attr(out[[v]], "format.sas") <- "DATETIME20"
  attr(out, "label") <- label

  write_xpt(out, file.path(out_dir, paste0(tolower(ds), ".xpt")), version = 5, name = toupper(ds))
  message(toupper(ds), ": ", nrow(out), " rows")
  invisible(out)
}
