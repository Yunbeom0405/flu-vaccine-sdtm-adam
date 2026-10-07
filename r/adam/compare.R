# Program : compare.R
# Purpose : Compare R ADaM (data/derived/adam-r) with SAS ADaM (data/derived/adam) using {diffdf}
# Output  : output/validation/adam-r-vs-sas.txt

library(haven)
library(diffdf)

keys <- list(
  adsl   = "USUBJID",
  adis   = c("USUBJID", "PARAMCD", "AVISITN"),
  adface = c("USUBJID", "PARAMCD", "ATPTN"),
  adce   = c("USUBJID", "CEDECOD", "ATPTN"),
  adae   = c("USUBJID", "AESEQ")
)

report <- "output/validation/adam-r-vs-sas.txt"
dir.create(dirname(report), showWarnings = FALSE, recursive = TRUE)
if (file.exists(report)) file.remove(report)

for (d in names(keys)) {
  sas_file <- file.path("data/derived/adam", paste0(d, ".xpt"))
  if (!file.exists(sas_file)) {
    message(d, ": no SAS file, skipped")
    next
  }
  sas <- read_xpt(sas_file)
  r <- read_xpt(file.path("data/derived/adam-r", paste0(d, ".xpt")))
  cat("\n=====", toupper(d), "=====\n", file = report, append = TRUE)
  res <- diffdf(sas, r, keys = keys[[d]], suppress_warnings = TRUE, tolerance = 1e-8)
  cat(if (length(res) == 0) "No issues found\n" else capture.output(print(res)),
      sep = "\n", file = report, append = TRUE)
  message(d, ": ", if (length(res) == 0) "match" else "DIFFERENCES - see report")
}
