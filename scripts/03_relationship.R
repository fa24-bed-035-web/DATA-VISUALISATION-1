# 03_relationship.R -- Question 3 (and the redesign for Question 4).
source("scripts/00_functions.R")
e <- load_earners()

bands <- band_table(e)
print(as.data.frame(bands |> select(band, n, mean_earn)))
write_csv(select(bands, band, n, mean_earn), "results/band_table_R.csv")   # compared by script 04

top <- bands |> slice_max(mean_earn, n = 1)
cat("Mean 25-29:", bands$mean_earn[bands$band == "25-29"],
    "| 45-49:", bands$mean_earn[bands$band == "45-49"],
    "| highest band:", top$band, "\n")

set.seed(346)  # jitter is random: fixed seed makes the figure identical on every run
p <- ggplot(e, aes(age, earn_annual)) +
  geom_jitter(width = 0.4, height = 0, alpha = 0.22, size = 0.9, colour = "grey35") +  # horizontal jitter <= 0.4 years
  geom_line(data = bands, aes(midpoint, mean_earn), colour = "#D9480F", linewidth = 0.9) +
  geom_point(data = bands, aes(midpoint, mean_earn, fill = thin), shape = 21, size = 3.6,
             stroke = 1.1, colour = "#D9480F") +
  scale_fill_manual(values = c(`FALSE` = "#D9480F", `TRUE` = "white"), guide = "none") +  # thin bands = hollow
  annotate("segment", x = top$midpoint - 9, xend = top$midpoint - 0.6, y = 2.2e6, yend = top$mean_earn * 1.12,
           colour = "#D9480F", arrow = arrow(length = unit(0.12, "inches"))) +
  annotate("text", x = top$midpoint - 9.5, y = 2.4e6, hjust = 1, vjust = 0, fontface = "bold", colour = "#D9480F",
           size = 3.6, label = paste0("Highest mean: ", top$band, "\n", fmt_rs(top$mean_earn))) +
  scale_y_log10(breaks = 10^(4:7), labels = c("Rs 10,000", "Rs 100,000", "Rs 1,000,000", "Rs 10,000,000")) +
  scale_x_continuous(breaks = seq(15, 65, 10), limits = c(14, 65)) +
  coord_cartesian(ylim = c(1e4, 1e7)) +
  labs(title = paste0("Earnings rise with age in urban Sindh, peaking at ages ", top$band),
       x = "Age (years)", y = "Annual earnings (log scale)",
       caption = paste0("Source: PSLM 2019-20. Sample: earners aged 15-64 in urban Sindh (n = ", nrow(e), ").\n",
                        "Weighting: hhweight; large markers are weighted mean earnings by 5-year age band.\n",
                        "Hollow markers: bands with fewer than 30 unweighted observations. Points jittered horizontally (max 0.4 years).")) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"),
        plot.caption = element_text(colour = "grey35", hjust = 0))

ggsave("figures/relationship.svg", p, width = 8, height = 5)
