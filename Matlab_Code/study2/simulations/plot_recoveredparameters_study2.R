library(tidyverse)

sim_dir <- "/Users/marianavonmohr/Desktop/Effort_computationalmodels/study2/simulations"

conf <- read.csv(
  file.path(sim_dir, "parameter_recovery_study2_2K1B_confusion_matrix.csv"),
  check.names = FALSE
)

conf_plot <- conf %>%
  mutate(
    simulated_parameter = recode(simulated_parameter,
                                 "k_agent1" = "K_rural",
                                 "k_agent2" = "K_urban",
                                 "beta" = "β"
    ),
    recovered_parameter = recode(recovered_parameter,
                                 "k_agent1" = "K_rural",
                                 "k_agent2" = "K_urban",
                                 "beta" = "β"
    ),
    simulated_parameter = factor(
      simulated_parameter,
      levels = c("K_rural", "K_urban", "β")
    ),
    recovered_parameter = factor(
      recovered_parameter,
      levels = rev(c("K_rural", "K_urban", "β"))
    )
  )

p_recovery_s2 <- ggplot(conf_plot, aes(x = simulated_parameter,
                                       y = recovered_parameter,
                                       fill = pearson_r)) +
  geom_tile(colour = "white", linewidth = 0.7) +
  geom_text(aes(label = sprintf("%.2f", pearson_r)), size = 5) +
  scale_fill_gradient2(
    low = "#F4E3A1",
    mid = "white",
    high = "#006D5B",
    midpoint = 0,
    limits = c(-0.25, 1),
    name = "r"
  ) +
  labs(
    x = "Simulated",
    y = "Recovered"
  ) +
  theme_classic(base_size = 18) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, colour = "black"),
    axis.text.y = element_text(colour = "black"),
    axis.title = element_text(size = 22, colour = "black"),
    legend.title = element_text(size = 18),
    legend.text = element_text(size = 14),
    axis.line = element_line(linewidth = 0.8)
  )

p_recovery_s2

ggsave(
  filename = file.path(sim_dir, "parameter_recovery_study2_heatmap.png"),
  plot = p_recovery_s2,
  width = 5,
  height = 4.5,
  dpi = 300
)
