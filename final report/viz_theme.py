"""
PROFESSIONAL BLUE THEME - Python/Matplotlib Styling Module
=============================================================
Mirrors visualization_theme.R's colour palette and styling conventions
so Python charts (Phase 3 forecasting, Phase 4 recommendations) match
the R ggplot2 outputs used elsewhere in the report.

Usage:
    from viz_theme import BLUE, BLUE_SEQUENCE, TREND_COLORS, apply_style, style_axes, save_fig

    apply_style()  # call once near the top of your script
    fig, ax = plt.subplots()
    ...
    style_axes(ax)
    save_fig(fig, OUTPUT_DIR / "my_chart.png")
"""

from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

# =========================================================
# 1. PROFESSIONAL BLUE PALETTE (matches visualization_theme.R)
# =========================================================
BLUE = {
    "primary":    "#1F4E79",   # Deep professional blue
    "secondary":  "#2E75B6",   # Medium blue
    "accent":     "#9DC3E6",   # Light blue
    "highlight":  "#00B0F0",   # Bright blue
    "light_bg":   "#F2F7FB",   # Very light blue background
    "text":       "#1A1A1A",   # Near-black text
    "text_light": "#4A5568",   # Muted grey for subtitles
    "grid":       "#D9E2EC",   # Subtle blue-grey grid
    "border":     "#B4C7E7",   # Blue border for elements
}

# Categorical sequence for multi-series charts (lines, grouped bars)
BLUE_SEQUENCE = [
    BLUE["primary"], BLUE["secondary"], BLUE["highlight"],
    BLUE["accent"], "#153A5B", "#5B93CC", "#71C1E8", "#C7DEF0",
]

# Trend colours kept within the blue family (dark = up, light = down)
# so directional charts still read as part of the same report
TREND_COLORS = {
    "Up": BLUE["primary"],
    "Flat": BLUE["text_light"],
    "Down": BLUE["accent"],
    "n/a": BLUE["text_light"],
}


def apply_style():
    """Call once per script to set global matplotlib defaults."""
    plt.rcParams.update({
        "font.family": "sans-serif",
        "text.color": BLUE["text"],
        "axes.edgecolor": BLUE["border"],
        "axes.labelcolor": BLUE["primary"],
        "axes.titlecolor": BLUE["primary"],
        "axes.titleweight": "bold",
        "axes.titlesize": 13,
        "axes.labelweight": "bold",
        "xtick.color": BLUE["text"],
        "ytick.color": BLUE["text"],
        "figure.facecolor": "white",
        "axes.facecolor": "white",
        "savefig.facecolor": "white",
        "legend.frameon": False,
        "grid.color": BLUE["grid"],
    })


def style_axes(ax, grid_axis="y", comma_format=True):
    """Consistent axis styling: strip top/right spines, light grid, comma-formatted numbers."""
    ax.spines[["top", "right"]].set_visible(False)
    ax.spines["left"].set_color(BLUE["border"])
    ax.spines["bottom"].set_color(BLUE["border"])
    if comma_format:
        ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x:,.0f}"))
    if grid_axis:
        ax.grid(axis=grid_axis, color=BLUE["grid"], alpha=0.7, linewidth=0.6)
    ax.set_axisbelow(True)


def save_fig(fig, path, dpi=200):
    """Save a figure with consistent settings, creating parent dirs if needed."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(path, dpi=dpi, bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(f"Saved: {path}")
