# Program : compare.R
# Purpose : Compare SAS SDTM (data/derived/sdtm) with R SDTM (data/derived/sdtm-r)
# Run from the P3 project root; every xpt found in sdtm-r is compared

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
  library(haven)
})

spec_ds <- read_excel("specs/sdtm-spec.xlsx", sheet = "Datasets")
spec_vars <- read_excel("specs/sdtm-spec.xlsx", sheet = "Variables")

report <- "output/validation/sdtm-r-vs-sas.txt"
dir.create(dirname(report), FALSE, TRUE)
if (file.exists(report)) file.remove(report)
say <- function(...) {
  line <- paste0(...)
  cat(line, "\n")
  cat(line, "\n", file = report, append = TRUE, sep = "")
}

# blank character is NA, numbers lose attributes
norm <- function(x) if (is.character(x)) na_if(trimws(x), "") else as.numeric(x)

same <- function(a, b) {
  both_na <- is.na(a) & is.na(b)
  eq <- if (is.numeric(a)) abs(a - b) < 1e-8 else a == b
  both_na | (!is.na(eq) & eq)
}

domain_of <- function(file) {
  d <- toupper(tools::file_path_sans_ext(file))
  if (d == "FACE") "FA" else d
}

total_diff <- 0
for (f in sort(list.files("data/derived/sdtm-r", pattern = "\\.xpt$"))) {
  dom <- domain_of(f)
  sas <- read_xpt(file.path("data/derived/sdtm", f))
  r <- read_xpt(file.path("data/derived/sdtm-r", f))
  keys <- strsplit(spec_ds$`Key Variables`[spec_ds$Dataset == dom], ",\\s*")[[1]]
  issues <- 0

  if (!identical(names(sas), names(r))) {
    say(dom, ": variable names or order differ")
    say("  only SAS: ", paste(setdiff(names(sas), names(r)), collapse = " "))
    say("  only R  : ", paste(setdiff(names(r), names(sas)), collapse = " "))
    issues <- issues + 1
  }
  vars <- intersect(names(sas), names(r))

  for (v in vars) {
    if (is.character(sas[[v]]) != is.character(r[[v]])) {
      say(dom, ".", v, ": type differs")
      issues <- issues + 1
    }
    ls <- attr(sas[[v]], "label")
    lr <- attr(r[[v]], "label")
    if (!identical(ls, lr)) {
      say(dom, ".", v, ": label SAS '", ls, "' R '", lr, "'")
      issues <- issues + 1
    }
  }

  for (k in keys) {
    s <- sas[[k]]
    t <- r[[k]]
    if (is.character(s) != is.character(t)) {
      say(dom, ": key ", k, " type differs")
      issues <- issues + 1
    }
  }
  dup_s <- sum(duplicated(sas[, keys]))
  dup_r <- sum(duplicated(r[, keys]))
  if (dup_s + dup_r > 0) {
    say(dom, ": duplicate keys SAS ", dup_s, " R ", dup_r)
    issues <- issues + 1
  }

  s <- sas[, vars] |> mutate(across(everything(), norm)) |> mutate(.s = TRUE)
  t <- r[, vars] |> mutate(across(everything(), norm)) |> mutate(.r = TRUE)
  m <- full_join(s, t, by = keys, suffix = c(".s", ".r"))
  only_s <- sum(is.na(m$.r))
  only_r <- sum(is.na(m$.s))
  if (only_s + only_r > 0) {
    say(dom, ": records only in SAS ", only_s, ", only in R ", only_r)
    issues <- issues + 1
  }
  both <- m |> filter(!is.na(.s) & !is.na(.r))

  for (v in setdiff(vars, keys)) {
    a <- both[[paste0(v, ".s")]]
    b <- both[[paste0(v, ".r")]]
    bad <- which(!same(a, b))
    if (length(bad) > 0) {
      say(dom, ".", v, ": ", length(bad), " of ", nrow(both), " differ")
      ex <- head(bad, 3)
      key_txt <- apply(both[ex, keys, drop = FALSE], 1, paste, collapse = "/")
      say("  e.g. ", paste0(key_txt, " SAS=", a[ex], " R=", b[ex], collapse = "; "))
      issues <- issues + 1
    }
  }

  say(dom, ": SAS ", nrow(sas), " x ", ncol(sas), ", R ", nrow(r), " x ", ncol(r),
    if (issues == 0) " -> MATCH" else paste0(" -> ", issues, " issue(s)"))
  total_diff <- total_diff + issues
}
say(if (total_diff == 0) "ALL MATCH" else paste0("DIFFERENCES: ", total_diff))
