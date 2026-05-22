library(tidyverse)

sim_dir <- "/Users/marianavonmohr/Desktop/Effort_computationalmodels/study2/simulations"

mi_xp <- read.csv(
  file.path(sim_dir, "model_identifiability_study2_confusion_XP.csv"),
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
  "ms_two_k_one_beta" = "2K1βp",
  "ms_two_k_one_beta_linear" = "2K1βl",
  "ms_two_k_one_beta_hyperbolic" = "2K1βh",
  "ms_two_k_two_beta" = "2K2βp",
  "ms_two_k_two_beta_linear" = "2K2βl",
  "ms_two_k_two_beta_hyperbolic" = "2K2βh"
)

model_order <- c(
  "ms_two_k_one_beta",
  "ms_two_k_one_beta_linear",
  "ms_two_k_one_beta_hyperbolic",
  "ms_two_k_two_beta",
  "ms_two_k_two_beta_linear",
  "ms_two_k_two_beta_hyperbolic"
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

p_mi_s2 <- ggplot(mi_plot, aes(x = simulated_label,
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

p_mi_s2

ggsave(
  filename = file.path(sim_dir, "model_identifiability_study2_XP_heatmap.png"),
  plot = p_mi_s2,
  width = 6,
  height = 5,
  dpi = 300
)

