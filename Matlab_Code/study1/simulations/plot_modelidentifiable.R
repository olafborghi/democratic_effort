library(tidyverse)

sim_dir <- "/Users/marianavonmohr/Desktop/Effort_computationalmodels/study1/simulations"

mi_xp <- read.csv(
  file.path(sim_dir, "model_identifiability_study1_confusion_XP.csv"),
  check.names = FALSE
)

# First column contains simulated model names
names(mi_xp)[1] <- "simulated_model"

# Long format
mi_long <- mi_xp %>%
  pivot_longer(
    cols = -simulated_model,
    names_to = "estimated_model",
    values_to = "count"
  )

# Short labels
label_map <- c(
  "ms_three_k_one_beta" = "3K1βp",
  "ms_three_k_one_beta_linear" = "3K1βl",
  "ms_three_k_one_beta_hyperbolic" = "3K1βh",
  "ms_three_k_three_beta" = "3K3βp",
  "ms_three_k_three_beta_linear" = "3K3βl",
  "ms_three_k_three_beta_hyperbolic" = "3K3βh"
)

model_order <- c(
  "ms_three_k_one_beta",
  "ms_three_k_one_beta_linear",
  "ms_three_k_one_beta_hyperbolic",
  "ms_three_k_three_beta",
  "ms_three_k_three_beta_linear",
  "ms_three_k_three_beta_hyperbolic"
)

mi_plot <- mi_long %>%
  mutate(
    simulated_model = factor(simulated_model, levels = model_order),
    estimated_model = factor(estimated_model, levels = rev(model_order)),
    simulated_label = label_map[as.character(simulated_model)],
    estimated_label = label_map[as.character(estimated_model)],
    simulated_label = factor(simulated_label, levels = label_map[model_order]),
    estimated_label = factor(estimated_label, levels = rev(label_map[model_order]))
  )

p_mi <- ggplot(mi_plot, aes(x = simulated_label,
                            y = estimated_label,
                            fill = count)) +
  geom_tile(colour = "white", linewidth = 0.7) +
  scale_fill_gradient(
    low = "#F5EFF8",
    high = "#006D5B",
    limits = c(0, 10),
    name = "Best\n(of 10)"
  ) +
  labs(
    x = "Simulated",
    y = "Estimated"
  ) +
  theme_classic(base_size = 18) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, colour = "black"),
    axis.text.y = element_text(colour = "black"),
    axis.title = element_text(size = 24, colour = "black"),
    legend.title = element_text(size = 18),
    legend.text = element_text(size = 14),
    axis.line = element_line(linewidth = 0.8)
  )

p_mi

ggsave(
  filename = file.path(sim_dir, "model_identifiability_study1_XP_heatmap.png"),
  plot = p_mi,
  width = 6,
  height = 5,
  dpi = 300
)

