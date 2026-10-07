# Program : t_14_1_01.R
# Purpose : Table 14-1.01 Summary of Populations, Disposition and Demographics

source("r/tlf/setup.R")

adsl <- read_adam("adsl") |>
  filter(RANDFL == "Y") |>
  mutate(TRT01P = factor(TRT01P, levels = trt_levels))

grp <- c(split(adsl, adsl$TRT01P), list(Total = adsl))
N <- sapply(grp, nrow)
k <- length(grp)
n_of <- function(fn) sapply(grp, \(d) sum(fn(d)))

rw <- 0
out <- list()
add <- function(x) { out[[length(out) + 1]] <<- x }
cl <- function(indent, label, fn) {
  rw <<- rw + 1
  add(mk(rw, indent, label, npct(n_of(fn), N)))
}
h <- function(indent, label) { rw <<- rw + 1; add(hdr(rw, indent, label, k)) }

cl(0, "Randomized", \(d) d$RANDFL == "Y")
cl(0, "Dosed (safety population)", \(d) d$SAFFL == "Y")
cl(0, "Immunogenicity per-protocol population", \(d) d$IMMFL == "Y")
cl(0, "Completed study", \(d) d$EOSSTT == "COMPLETED")
cl(0, "Discontinued study", \(d) d$EOSSTT == "DISCONTINUED")
cl(1, "Lost to follow-up", \(d) d$DCSREAS %in% "LOST TO FOLLOW-UP")
cl(1, "Withdrawal by subject", \(d) d$DCSREAS %in% "WITHDRAWAL BY SUBJECT")

h(0, "Age (years)")
rw <- rw + 1; add(mk(rw, 1, "n", sapply(grp, \(d) as.character(nrow(d)))))
rw <- rw + 1; add(mk(rw, 1, "Mean (SD)", sapply(grp, \(d) paste0(f(mean(d$AGE), 1), " (", f(sd(d$AGE), 2), ")"))))
rw <- rw + 1; add(mk(rw, 1, "Median", sapply(grp, \(d) f(median(d$AGE), 1))))
rw <- rw + 1; add(mk(rw, 1, "Min; Max", sapply(grp, \(d) paste0(f(min(d$AGE), 0), "; ", f(max(d$AGE), 0)))))

h(0, "Age group")
cl(1, "18-45", \(d) d$AGEGR1 == "18-45")
cl(1, "46-60", \(d) d$AGEGR1 == "46-60")
h(0, "Sex")
cl(1, "Female", \(d) d$SEX == "F")
cl(1, "Male", \(d) d$SEX == "M")
h(0, "Race")
for (r in c("ASIAN", "BLACK OR AFRICAN AMERICAN", "WHITE", "OTHER")) {
  cl(1, tools::toTitleCase(tolower(r)), \(d) d$RACE == r)
}
h(0, "Ethnicity")
cl(1, "Hispanic or Latino", \(d) d$ETHNIC == "HISPANIC OR LATINO")
cl(1, "Not Hispanic or Latino", \(d) d$ETHNIC == "NOT HISPANIC OR LATINO")

df <- bind_rows(out) |> rename_with(~ paste0("C", seq_len(k)), starts_with("C"))
save_df(df, "t_14_1_01", "Table 14-1.01 Summary of Populations, Disposition and Demographics",
  paste0(c(trt_levels, "Total"), " (N=", N, ")"),
  c("Population: randomized. Percentages use N in the column header; arms are as randomized.",
    "27 screen failures are not in this table. Synthetic data."))
