options(repr.plot.width = 10, repr.plot.height = 6, repr.plot.res = 110)

# Shared chart styling.
theme_wp3 <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(color = "#17313B", face = "bold", size = 15),
      plot.subtitle = ggplot2::element_text(color = "#52666F", margin = ggplot2::margin(b = 10)),
      axis.title = ggplot2::element_text(color = "#334B55", face = "bold"),
      axis.text = ggplot2::element_text(color = "#52666F"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(color = "#E6ECEF", linewidth = 0.35),
      strip.background = ggplot2::element_rect(fill = "#EDF2F4", color = NA),
      strip.text = ggplot2::element_text(color = "#17313B", face = "bold"),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(color = "#334B55", face = "bold"),
      plot.background = ggplot2::element_rect(fill = "white", color = NA)
    )
}

# A restrained, color-blind-aware palette for a small number of experts.
expert_palette <- c("#355C7D", "#B36A4C", "#5B8063", "#84659A", "#A7833F", "#477C82")
teal_low <- "#F1F7F6"; teal_high <- "#176B6E"
rust_low <- "#FFF4E9"; rust_high <- "#C75B45"

# White labels on dark tiles, slate labels on light tiles.
label_colour_scale <- ggplot2::scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = "#17313B"), guide = "none")