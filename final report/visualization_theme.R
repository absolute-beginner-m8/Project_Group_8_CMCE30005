# =========================================================
# PROFESSIONAL BLUE THEME - CENTRALIZED STYLING GUIDE
# =========================================================
# Place this at the very top of your script (after library imports)
# Use these functions and palette consistently across ALL plots

library(ggplot2)
library(dplyr)
library(scales)
library(grid)
library(rlang)

# =========================================================
# 1. PROFESSIONAL BLUE PALETTE
# =========================================================
blue_palette <- list(
  primary      = "#1F4E79",    # Deep professional blue
  secondary    = "#2E75B6",    # Medium blue
  accent       = "#9DC3E6",    # Light blue
  highlight    = "#00B0F0",    # Bright blue
  light_bg     = "#F2F7FB",    # Very light blue background
  text         = "#1A1A1A",    # Near-black text
  text_light   = "#4A5568",    # Muted grey for subtitles
  grid         = "#D9E2EC",    # Subtle blue-grey grid
  border       = "#B4C7E7"     # Blue border for elements
)

# =========================================================
# 2. REUSABLE PROFESSIONAL THEME FUNCTION
# =========================================================
theme_report <- function(base_size = 12,
                         grid_type = "y",      # "x", "y", "both", "none"
                         legend_pos = "right") {

  theme_minimal(base_size = base_size) +
    theme(
      # ---- TEXT & TYPOGRAPHY ----
      text = element_text(
        family = "sans",
        color = blue_palette$text
      ),
      plot.title = element_text(
        face = "bold",
        size = 16,
        color = blue_palette$primary,
        margin = margin(b = 8, t = 5)
      ),
      plot.subtitle = element_text(
        size = 11,
        color = blue_palette$text_light,
        margin = margin(b = 12)
      ),
      plot.caption = element_text(
        size = 9,
        color = blue_palette$text_light,
        hjust = 0,
        margin = margin(t = 10)
      ),

      # ---- AXIS STYLING ----
      axis.title.x = element_text(
        face = "bold",
        size = 11,
        color = blue_palette$primary,
        margin = margin(t = 8)
      ),
      axis.title.y = element_text(
        face = "bold",
        size = 11,
        color = blue_palette$primary,
        margin = margin(r = 8)
      ),
      axis.text.x = element_text(
        size = 10,
        color = blue_palette$text,
        angle = 0,
        hjust = 0.5
      ),
      axis.text.y = element_text(
        size = 10,
        color = blue_palette$text
      ),
      axis.line = element_line(
        color = blue_palette$border,
        linewidth = 0.5
      ),

      # ---- GRID STYLING ----
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),

      # Apply grid based on grid_type parameter
      panel.grid.major.y = if (grid_type %in% c("y", "both")) {
        element_line(color = blue_palette$grid, linewidth = 0.4, linetype = "solid")
      } else {
        element_blank()
      },

      panel.grid.major.x = if (grid_type %in% c("x", "both")) {
        element_line(color = blue_palette$grid, linewidth = 0.4, linetype = "solid")
      } else {
        element_blank()
      },

      # ---- PANEL & BACKGROUND ----
      panel.background = element_rect(
        fill = "white",
        color = NA
      ),
      plot.background = element_rect(
        fill = "white",
        color = NA
      ),
      panel.border = element_rect(
        fill = NA,
        color = blue_palette$border,
        linewidth = 0.5
      ),

      # ---- LEGEND STYLING ----
      legend.position = legend_pos,
      legend.background = element_rect(
        fill = blue_palette$light_bg,
        color = blue_palette$border,
        linewidth = 0.5
      ),
      legend.title = element_text(
        face = "bold",
        size = 10,
        color = blue_palette$primary
      ),
      legend.text = element_text(
        size = 9,
        color = blue_palette$text
      ),
      legend.key = element_rect(
        fill = "white",
        color = NA
      ),
      legend.key.height = unit(1.2, "cm"),
      legend.key.width = unit(0.8, "cm"),

      # ---- MARGINS & SPACING ----
      plot.margin = margin(15, 20, 15, 15),
      strip.text = element_text(
        face = "bold",
        size = 10,
        color = blue_palette$primary
      ),
      strip.background = element_rect(
        fill = blue_palette$light_bg,
        color = blue_palette$border,
        linewidth = 0.5
      )
    )
}

# =========================================================
# 3. REUSABLE COLOR SCALES
# =========================================================

# Continuous gradient (blue shades)
scale_fill_blue_gradient <- function(name = "Value", ...) {
  scale_fill_gradient(
    name = name,
    low = blue_palette$accent,
    high = blue_palette$primary,
    ...
  )
}

# Alternative: diverging blue gradient
scale_fill_blue_diverging <- function(name = "Value", ...) {
  scale_fill_gradient2(
    name = name,
    low = blue_palette$highlight,
    mid = "white",
    high = blue_palette$primary,
    midpoint = 0,
    ...
  )
}

# Discrete blue palette (for categorical data)
scale_fill_blue_discrete <- function(name = "Category", ...) {
  scale_fill_manual(
    name = name,
    values = c(
      blue_palette$primary,
      blue_palette$secondary,
      blue_palette$highlight,
      blue_palette$accent,
      "#153A5B",
      "#5B93CC",
      "#71C1E8",
      "#C7DEF0"
    ),
    ...
  )
}

# Continuous gradient for color (alt to fill)
scale_color_blue_gradient <- function(name = "Value", ...) {
  scale_color_gradient(
    name = name,
    low = blue_palette$accent,
    high = blue_palette$primary,
    ...
  )
}

# =========================================================
# 4. UTILITY FUNCTIONS FOR CONSISTENT FORMATTING
# =========================================================

# Format large numbers with K/M suffix
format_number_short <- function(x) {
  if_else(
    abs(x) >= 1e6,
    paste0(round(x / 1e6, 1), "M"),
    if_else(
      abs(x) >= 1e3,
      paste0(round(x / 1e3, 0), "K"),
      as.character(round(x, 0))
    )
  )
}

# Create consistent plot labels
create_plot_title <- function(title, subtitle = NULL) {
  list(
    title = title,
    subtitle = subtitle
  )
}

# =========================================================
# 5. STANDARD PLOT PATTERNS
# =========================================================

# Pattern 1: Horizontal bar chart (for rankings)
plot_horizontal_bars <- function(data, x_var, y_var, fill_var = NULL,
                                  title, subtitle = NULL, n_top = 20) {

  x_var <- enquo(x_var)
  y_var <- enquo(y_var)
  fill_var <- enquo(fill_var)

  plot_data <- data %>%
    slice_head(n = n_top) %>%
    mutate(!!quo_name(x_var) := reorder(!!x_var, !!y_var))

  p <- plot_data %>%
    ggplot(aes(x = !!x_var, y = !!y_var, fill = !!fill_var))

  if (quo_is_null(fill_var)) {
    p <- p + geom_col(fill = blue_palette$primary, width = 0.75)
  } else {
    p <- p + geom_col(width = 0.75) +
      scale_fill_blue_gradient()
  }

  p <- p +
    coord_flip() +
    labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = NULL,
      fill = NULL
    ) +
    theme_report(grid_type = "x")

  return(p)
}

# Pattern 2: Time series line plot
plot_time_series <- function(data, x_var, y_var, group_var = NULL,
                              title, subtitle = NULL) {

  x_var <- enquo(x_var)
  y_var <- enquo(y_var)
  group_var <- enquo(group_var)

  p <- data %>%
    ggplot(aes(x = !!x_var, y = !!y_var, color = !!group_var,
               group = !!group_var))

  if (quo_is_null(group_var)) {
    p <- p +
      geom_line(color = blue_palette$primary, linewidth = 1) +
      geom_point(color = blue_palette$secondary, size = 2)
  } else {
    p <- p +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      scale_color_manual(
        values = c(
          blue_palette$primary,
          blue_palette$secondary,
          blue_palette$highlight,
          blue_palette$accent,
          "#153A5B",
          "#5B93CC",
          "#71C1E8",
          "#C7DEF0"
        )
      )
  }

  p <- p +
    labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = NULL,
      color = NULL
    ) +
    theme_report(grid_type = "y", legend_pos = "top")

  return(p)
}

# Pattern 3: Scatter plot
plot_scatter <- function(data, x_var, y_var, color_var = NULL, size_var = NULL,
                         title, subtitle = NULL) {

  x_var <- enquo(x_var)
  y_var <- enquo(y_var)
  color_var <- enquo(color_var)
  size_var <- enquo(size_var)

  p <- data %>%
    ggplot(aes(x = !!x_var, y = !!y_var, color = !!color_var,
               size = !!size_var))

  if (quo_is_null(color_var) && quo_is_null(size_var)) {
    p <- p + geom_point(color = blue_palette$primary, size = 3, alpha = 0.7)
  } else if (quo_is_null(size_var)) {
    p <- p +
      geom_point(alpha = 0.7, size = 3) +
      scale_color_blue_gradient()
  } else if (quo_is_null(color_var)) {
    p <- p +
      geom_point(alpha = 0.7) +
      scale_size_continuous(name = NULL) +
      scale_color_manual(values = blue_palette$primary)
  } else {
    p <- p +
      geom_point(alpha = 0.7) +
      scale_size_continuous(name = NULL) +
      scale_color_blue_gradient()
  }

  p <- p +
    labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = NULL,
      color = NULL,
      size = NULL
    ) +
    theme_report(grid_type = "both")

  return(p)
}

# Pattern 4: Distribution plot
plot_distribution <- function(data, x_var, fill_var = NULL,
                               title, subtitle = NULL, bins = 30) {

  x_var <- enquo(x_var)
  fill_var <- enquo(fill_var)

  p <- data %>%
    ggplot(aes(x = !!x_var, fill = !!fill_var))

  if (quo_is_null(fill_var)) {
    p <- p +
      geom_histogram(bins = bins, fill = blue_palette$primary,
                     color = blue_palette$border, alpha = 0.9)
  } else {
    p <- p +
      geom_histogram(bins = bins, color = blue_palette$border,
                     alpha = 0.9, position = "dodge") +
      scale_fill_blue_discrete()
  }

  p <- p +
    labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = "Count",
      fill = NULL
    ) +
    theme_report(grid_type = "y")

  return(p)
}

# =========================================================
# 6. EXPORT FUNCTION (consistent settings)
# =========================================================

export_plot <- function(plot, filename, width = 10, height = 7, dpi = 300) {
  ggsave(
    filename = filename,
    plot = plot,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )
  cat(sprintf("Saved: %s\n", filename))
}

# =========================================================
# END OF THEME SETUP
# =========================================================
