library(tidyverse)

# Path
sim_dir <- "/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/simulations"

# Load parameter recovery confusion matrix
conf <- read.csv(file.path(sim_dir, "parameter_recovery_study1_3K1B_confusion_matrix.csv"))

# Clean labels for plotting
conf_plot <- conf %>%
  mutate(
    simulated_parameter = recode(simulated_parameter,
                                 "k_agent1" = "K_all",
                                 "k_agent2" = "K_rural",
                                 "k_agent3" = "K_urban",
                                 "beta" = "β"
    ),
    recovered_parameter = recode(recovered_parameter,
                                 "k_agent1" = "K_all",
                                 "k_agent2" = "K_rural",
                                 "k_agent3" = "K_urban",
                                 "beta" = "β"
    ),
    simulated_parameter = factor(simulated_parameter,
                                 levels = c("K_all", "K_rural", "K_urban", "β")
    ),
    recovered_parameter = factor(recovered_parameter,
                                 levels = rev(c("K_all", "K_rural", "K_urban", "β"))
    )
  )

# Plot
p_recovery <- ggplot(conf_plot, aes(x = simulated_parameter,
                                    y = recovered_parameter,
                                    fill = pearson_r)) +
  geom_tile(colour = "white", linewidth = 0.6) +
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
    axis.text.x = element_text(angle = 45, hjust = 1),
    axis.title = element_text(size = 22),
    legend.title = element_text(size = 18),
    legend.text = element_text(size = 14)
  )

p_recovery

ggsave(
  filename = file.path(sim_dir, "parameter_recovery_study1_heatmap.png"),
  plot = p_recovery,
  width = 6,
  height = 5,
  dpi = 300
)

