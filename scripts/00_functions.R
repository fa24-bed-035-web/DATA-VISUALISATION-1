# 00_functions.R -- helpers shared by the figure scripts (sourced, not run alone).
# Run every script from the repository root (the folder that contains data/).
library(dplyr)
library(readr)
library(ggplot2)

# Variant 3 = Sindh (prov_code 3), urban (urban_rural 2).
# 35 = 4 x 8 + 3, so the last two digits of FA24-BEDS-035 give variant 3.
VARIANT_PROV  <- 3
VARIANT_URBAN <- 2

load_earners <- function() {
  if (!file.exists("data/pslm_person_subset.csv"))
    stop("Run this script from the repository root (the folder containing data/).")
  person <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
  hh     <- read_csv("data/pslm_hh_subset.csv", show_col_types = FALSE)

  person |>
    # the person file has no weight, province or area: attach them by hhid
    left_join(select(hh, hhid, hhweight, prov_code, urban_rural), by = "hhid") |>
    # earners of my variant: aged 15-64 with annual earnings above zero
    filter(prov_code == VARIANT_PROV, urban_rural == VARIANT_URBAN,
           age >= 15, age <= 64, earn_annual > 0)
}

# weighted mean = sum(w * x) / sum(w)
wmean <- function(x, w) sum(w * x) / sum(w)

# weighted p-th quantile: sort by x, take the cumulative share of weight,
# return the smallest x whose share reaches or exceeds p.
wquantile <- function(x, w, p) {
  o  <- order(x)
  xs <- x[o]
  cs <- cumsum(w[o]) / sum(w)
  xs[which(cs >= p - 1e-12)[1]]   # tiny tolerance guards against floating-point error
}

fmt_rs <- function(v) paste0("Rs ", format(round(v), big.mark = ",", scientific = FALSE, trim = TRUE))

# five-year age bands, right-open: [15,20), [20,25), ... ; midpoints 17, 22, ... 62
band_table <- function(e) {
  e |>
    mutate(band_start = floor(age / 5) * 5) |>
    group_by(band_start) |>
    summarise(n = n(), mean_earn = round(wmean(earn_annual, hhweight)), .groups = "drop") |>
    mutate(band = paste0(band_start, "-", band_start + 4),
           midpoint = band_start + 2,
           thin = n < 30)
}
