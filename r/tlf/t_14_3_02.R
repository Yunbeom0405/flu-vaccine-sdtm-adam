# Program : t_14_3_02.R
# Purpose : Table 14-3.02 Unsolicited Adverse Events through Day 22 and Serious Adverse Events through Day 91

source("r/tlf/setup.R")

adsl <- read_adam("adsl") |> filter(SAFFL == "Y")
N <- sapply(trt_levels, \(t) sum(adsl$TRT01A == t))

adae <- read_adam("adae") |>
  filter(SAFFL == "Y") |>
  mutate(COL = match(TRT01A, trt_levels))

rw <- 0
out <- list()
add <- function(x) { out[[length(out) + 1]] <<- x }
line <- function(indent, label, n) { rw <<- rw + 1; add(mk(rw, indent, label, npct(n, N, 1))) }
subj <- function(d) sapply(1:2, \(i) n_distinct(d$USUBJID[d$COL == i]))

# one section: any, then SOC / PT by descending total subjects, ties alphabetical
section <- function(any_label, flag, by_soc) {
  d <- filter(adae, .data[[flag]] %in% "Y")
  line(0, any_label, subj(d))
  pts <- d |> distinct(AEBODSYS, AEDECOD)
  pt_n <- t(mapply(\(s, p) subj(filter(d, AEBODSYS == s, AEDECOD == p)), pts$AEBODSYS, pts$AEDECOD))
  pts <- bind_cols(pts, tibble(n1 = pt_n[, 1], n2 = pt_n[, 2], tot = pt_n[, 1] + pt_n[, 2]))
  if (by_soc) {
    socs <- d |> distinct(AEBODSYS)
    soc_n <- t(sapply(socs$AEBODSYS, \(s) subj(filter(d, AEBODSYS == s))))
    socs <- mutate(socs, n1 = soc_n[, 1], n2 = soc_n[, 2], tot = n1 + n2)
    for (s in socs$AEBODSYS[order(-socs$tot, socs$AEBODSYS, method = "radix")]) {
      line(1, s, unlist(socs[socs$AEBODSYS == s, c("n1", "n2")]))
      p <- filter(pts, AEBODSYS == s)
      p <- p[order(-p$tot, p$AEDECOD, method = "radix"), ]
      for (i in seq_len(nrow(p))) line(2, p$AEDECOD[i], c(p$n1[i], p$n2[i]))
    }
  } else {
    pts <- pts[order(-pts$tot, pts$AEDECOD, method = "radix"), ]
    for (i in seq_len(nrow(pts))) line(1, pts$AEDECOD[i], c(pts$n1[i], pts$n2[i]))
  }
}

section("Any unsolicited AE through Day 22", "ANL01FL", TRUE)
section("Any serious AE through Day 91", "ANL02FL", FALSE)

df <- bind_rows(out)
save_df(df, "t_14_3_02", "Table 14-3.02 Adverse Events (Unsolicited through Day 22, Serious through Day 91)",
  paste0(trt_levels, " (N=", N, ")"),
  c("Population: safety, arms as treated. Subjects counted once per term. Treatment-emergent events only.",
    "No MedDRA: system organ class and preferred term come from a local coding table."))
