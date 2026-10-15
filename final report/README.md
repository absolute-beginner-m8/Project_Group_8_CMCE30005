# Final Report - Folder Guide

## Where things are

**Graphs/**
- `R_Plots_PDF/` - all ggplot2 charts (from `Suhan_vehicle_analysis_Refactored.R` and `PredictionAndCode_Refactored.R`), as PDFs, blue-themed
- `Python_Charts_PNG/` - copies of the Phase 3/4 matplotlib charts, blue-themed (originals auto-regenerate in `outputs/forecasts/charts/` each time the Python scripts run)

**Data_Outputs/CSV/**
- Result tables from the R analysis: market summaries, growth rankings, top-20 models, RF/Linear demand-change rankings

**Reports/**
- `model_performance_comparison.html` - styled model comparison table (MAE/RMSE/R2 across Linear/Tree/RF/XGBoost)

**outputs/** (Python-generated, left in its original structure)
- `forecasts/` - Phase 3 forecast CSV, Phase 4 recommendation CSVs, and `charts/` (same PNGs copied above)
- `results/` - Phase 3 model comparison CSV

## Scripts

| Script | What it does | Run with |
|---|---|---|
| `visualization_theme.R` | Shared blue theme/plot functions for all R scripts - source this first | (sourced automatically) |
| `viz_theme.py` | Python equivalent of the blue theme, for matplotlib charts | (imported automatically) |
| `Suhan_vehicle_analysis_Refactored.R` | Data cleaning + exploratory/market analysis + 8 charts | RStudio |
| `PredictionAndCode_Refactored.R` | Full ML pipeline (Linear/Tree/RF/XGBoost/NN) + demand forecasts + 2 ranking charts + comparison table | RStudio |
| `phase_3_forecasting_refactored.py` | ARIMA vs XGBoost time-series forecast (6-month horizon) | `python3 phase_3_forecasting_refactored.py` in Terminal |
| `phase4_recommendations_refactored.py` | Stocking recommendations (new vs used, top makes/models, trending now) | `python3 phase4_recommendations_refactored.py` in Terminal |

The `_Refactored` versions are the ones to run - they have the consistent blue
theme applied and organized output paths. The non-"_Refactored" files
(`PredictionAndCode.R`, `Suhan_vehicle_analysis.R`, `phase_3_forecasting.py`,
`phase4_recommendations.py`) are kept as the original reference copies.

Re-running any `_Refactored` script will regenerate its outputs directly into
the folders above - nothing lands loose in this top-level folder anymore.
