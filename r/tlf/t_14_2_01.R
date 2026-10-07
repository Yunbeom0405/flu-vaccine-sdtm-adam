# Program : t_14_2_01.R
# Purpose : Table 14-2.01 HAI Immunogenicity: GMT, GMFR, Seroprotection, Seroconversion

source("r/tlf/setup.R")

adsl <- read_adam("adsl") |> filter(IMMFL == "Y")
N <- sapply(trt_levels, \(t) sum(adsl$TRT01P == t))

adis <- read_adam("adis") |>
  filter(ANL01FL == "Y") |>
  mutate(TRT01P = factor(TRT01P, levels = trt_levels))

# GMT / GMFR: mean of ln(value), t-based 95% CI, back-transformed
gm <- function(x) {
  n <- length(x); m <- mean(log(x)); s <- sd(log(x)); t <- qt(0.975, n - 1)
  paste0(f(exp(m), 1), " (", f(exp(m - t * s / sqrt(n)), 1), "; ", f(exp(m + t * s / sqrt(n)), 1), ")")
}

out <- list()
strains <- c("A", "B", "C")
for (p in 1:3) {
  b <- (p - 1) * 14
  sub <- filter(adis, PARAMN == p)
  by_arm <- function(visit) lapply(trt_levels, \(t) filter(sub, AVISITN == visit, TRT01P == t))
  d1 <- by_arm(2)
  d22 <- by_arm(4)
  v <- function(fn, d) sapply(d, fn)
  cnt <- function(d, col, val = "Y") sapply(d, \(x) sum(x[[col]] %in% val))
  den <- function(d, col) sapply(d, \(x) sum(!is.na(x[[col]])))
  out <- c(out, list(
    hdr(b + 1, 0, paste("HAI titer, Strain", strains[p]), 2),
    hdr(b + 2, 1, "Day 1", 2),
    mk(b + 3, 2, "n", as.character(v(nrow, d1))),
    mk(b + 4, 2, "GMT (95% CI)", v(\(x) gm(x$AVAL), d1)),
    mk(b + 5, 2, "Seroprotection (titer >= 40), n", npct(cnt(d1, "CRIT1FL"), v(nrow, d1), 1)),
    mk(b + 6, 3, "95% CI", cp_ci(cnt(d1, "CRIT1FL"), v(nrow, d1))),
    hdr(b + 7, 1, "Day 22", 2),
    mk(b + 8, 2, "n", as.character(v(nrow, d22))),
    mk(b + 9, 2, "GMT (95% CI)", v(\(x) gm(x$AVAL), d22)),
    mk(b + 10, 2, "GMFR, Day 22 / Day 1 (95% CI)", v(\(x) gm(x$R2BASE), d22)),
    mk(b + 11, 2, "Seroprotection (titer >= 40), n", npct(cnt(d22, "CRIT1FL"), v(nrow, d22), 1)),
    mk(b + 12, 3, "95% CI", cp_ci(cnt(d22, "CRIT1FL"), v(nrow, d22))),
    mk(b + 13, 2, "Seroconversion, n", npct(cnt(d22, "CRIT2FL"), den(d22, "CRIT2FL"), 1)),
    mk(b + 14, 3, "95% CI", cp_ci(cnt(d22, "CRIT2FL"), den(d22, "CRIT2FL")))
  ))
}

df <- bind_rows(out)
save_df(df, "t_14_2_01", "Table 14-2.01 HAI Immunogenicity by Strain",
  paste0(trt_levels, " (N=", N, ")"),
  c("Population: immunogenicity per-protocol. Titers below the LLOQ (10) are set to 5 for GMT and GMFR.",
    "Seroconversion: baseline < 10 and Day 22 >= 40, or baseline >= 10 and 4-fold rise. 95% CI: t on ln(titer) for GMT/GMFR, Clopper-Pearson for percentages."))
