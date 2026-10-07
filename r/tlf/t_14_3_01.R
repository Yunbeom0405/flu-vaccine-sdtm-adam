# Program : t_14_3_01.R
# Purpose : Table 14-3.01 Solicited Local and Systemic Reactions by Maximum Grade

source("r/tlf/setup.R")

adsl <- read_adam("adsl") |> filter(SAFFL == "Y")
adsl_n <- sapply(c("VAXF-101 0.5 mL", "Placebo"), \(t) sum(adsl$TRT01A == t))
N <- adsl_n

adce <- read_adam("adce") |>
  filter(SAFFL == "Y") |>
  mutate(TRT01A = factor(TRT01A, levels = trt_levels))
grp <- split(adce, adce$TRT01A)

rw <- 0
out <- list()
add <- function(x) { out[[length(out) + 1]] <<- x }
cl <- function(indent, label, fn) {
  rw <<- rw + 1
  add(mk(rw, indent, label, npct(sapply(grp, \(d) sum(fn(d))), N, 1)))
}
h <- function(indent, label) { rw <<- rw + 1; add(hdr(rw, indent, label, 2)) }

reactions <- c("PAIN", "TENDERNESS", "REDNESS", "SWELLING", "INDURATION", "FEVER", "CHILLS", "MALAISE",
               "MYALGIA", "HEADACHE", "ARTHRALGIA", "NAUSEA", "VOMITING")
wins <- c("Within 30 minutes after vaccination" = 0, "Within 7 days after vaccination" = 8)

for (w in seq_along(wins)) {
  wn <- wins[[w]]
  h(0, names(wins)[w])
  for (sc in c("LOCAL", "SYSTEMIC")) {
    cl(1, paste("Any", tolower(sc), "reaction"), \(d) d$ATPTN == wn & d$AOCCSFL %in% "Y" & d$CESCAT == sc)
    for (g in 1:4) {
      cl(2, paste("Maximum grade", g), \(d) d$ATPTN == wn & d$AOCCSFL %in% "Y" & d$CESCAT == sc & d$ATOXGRN == g)
    }
  }
  for (r in reactions) {
    lab <- tools::toTitleCase(tolower(r))
    cl(1, lab, \(d) d$ATPTN == wn & d$CEDECOD == r & d$ATOXGRN >= 1)
    cl(2, "Grade 2 or higher", \(d) d$ATPTN == wn & d$CEDECOD == r & d$ATOXGRN >= 2)
  }
}

df <- bind_rows(out)
save_df(df, "t_14_3_01", "Table 14-3.01 Solicited Local and Systemic Reactions by Maximum Grade",
  paste0(trt_levels, " (N=", N, ")"),
  c("Population: safety (randomized and dosed), arms as treated. Subjects counted once per reaction at the maximum grade.",
    "FDA 2007 toxicity grading scale for preventive vaccine trials. Diameters under 25 mm are not reactions."))
