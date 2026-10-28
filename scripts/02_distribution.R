# 02_distribution.R -- Question 2: weighted histogram of earnings on a log10 scale.
source("scripts/00_functions.R")
e <- load_earners()

# --- headline numbers -------------------------------------------------------
w_med <- wquantile(e$earn_annual, e$hhweight, 0.50)
p10   <- wquantile(e$earn_annual, e$hhweight, 0.10)
p90   <- wquantile(e$earn_annual, e$hhweight, 0.90)
inside   <- e |> filter(earn_annual >= 1e4, earn_annual <= 1e7)
excluded <- nrow(e) - nrow(inside)

cat("Earners:", nrow(e), "\n")
cat("Weighted median:", round(w_med), "| unweighted median:", median(e$earn_annual), "\n")
cat("Weighted P10:", round(p10), "| P90:", round(p90), "| P90/P10:", sprintf("%.2f", p90 / p10), "\n")
cat("Excluded (outside Rs 10,000 - 10,000,000):", excluded, "\n")

# --- weighted histogram, bins 0.1 wide in log10 units, 4.0 to 7.0 ------------
# bin index 0..29; round() before floor() protects against floating-point edge cases
hist_df <- inside |>
  mutate(lx  = log10(earn_annual),
         bin = pmin(floor(round(lx * 10, 8)), 69) - 40) |>     # lx = 7.0 goes in the last bin
  group_by(bin) |>
  summarise(w = sum(hhweight), .groups = "drop") |>
  right_join(tibble(bin = 0:29), by = "bin") |>
  mutate(w = coalesce(w, 0),
         density = w / sum(w) / 0.1,       # share of weight per log10 unit (area = 1)
         mid = 4 + bin * 0.1 + 0.05)

p <- ggplot(hist_df, aes(mid, density)) +
  geom_col(width = 0.1, fill = "#0F766E", colour = "white", linewidth = 0.2) +
  geom_vline(xintercept = log10(c(w_med, p90)), linetype = "dashed", colour = "#D9480F", linewidth = 0.7) +
  annotate("text", x = log10(w_med) - 0.04, y = max(hist_df$density) * 1.22, hjust = 1, vjust = 1,
           label = paste0("Median\n", fmt_rs(w_med)), colour = "#D9480F", fontface = "bold", size = 3.6) +
  annotate("text", x = log10(p90) + 0.04, y = max(hist_df$density) * 0.80, hjust = 0, vjust = 1,
           label = paste0("90th percentile\n", fmt_rs(p90)), colour = "#D9480F", fontface = "bold", size = 3.6) +
  scale_x_continuous(breaks = 4:7, limits = c(4, 7),
                     labels = c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")) +
  scale_y_continuous(limits = c(0, max(hist_df$density) * 1.27), expand = c(0, 0)) +
  labs(title = paste0("Urban Sindh earnings cluster near ", fmt_rs(w_med), ", with a long right tail"),
       x = "Annual earnings (log scale)", y = "Density per log10 unit",
       caption = paste0("Source: PSLM 2019-20. Sample: earners aged 15-64 in urban Sindh (n = ", nrow(e), "). ",
                        "Weighted by hhweight.\n", excluded, " earners outside Rs 10,000 - Rs 10,000,000 are excluded.")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold"), plot.caption = element_text(colour = "grey35", hjust = 0))

ggsave("figures/distribution.svg", p, width = 8, height = 5)
