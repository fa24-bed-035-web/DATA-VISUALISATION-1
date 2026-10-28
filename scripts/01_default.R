# 01_default.R -- Question 4: R's default scatterplot, nothing added.
source("scripts/00_functions.R")
e <- load_earners()

p <- ggplot(e, aes(age, earn_annual)) + geom_point()
ggsave("figures/default.svg", p, width = 8, height = 5)
cat("Saved figures/default.svg with", nrow(e), "earners\n")
