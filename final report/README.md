# Final Report - Folder Guide

Last updated: 15 October 2026. Project overview and results are in the main `../README.md`.

## Where things are

**Graphs/**
- `R_Plots_PDF/` - ggplot2 charts (from `Suhan_vehicle_analysis_Refactored.R` and `PredictionAndCode_Refactored.R`), blue-themed PDFs
- `Python_Charts_PNG/` - copies of the Phase 3 and Phase 4 matplotlib charts. The originals regenerate in `outputs/forecasts/charts/` each time the Python scripts run, so copy them across after a re-run.

**Data_Outputs/CSV/**
- R result tables: market summaries, growth rankings, top-20 models, linear and random forest demand-change rankings

**Reports/**
- `model_performance_comparison.html` - model comparison table (MAE, RMSE, R2 for Linear, Tree, RF, XGBoost)

**outputs/** (written by the Python scripts)
- `forecasts/` - Phase 3 6-month forecast CSV, Phase 4 recommendation CSVs, and `charts/`
- `results/` - `phase3_model_comparison.csv` (ARIMA and XGBoost, multi-step and 1-step)

**_archive/** (not needed to run anything)
- `original_versions/` - the pre-refactor scripts (`PredictionAndCode.R`, `Suhan_vehicle_analysis.R`, `phase_3_forecasting.py`, `phase4_recommendations.py`)
- `backups/` - `.bak` copies of scripts and the previous READMEs
- `previous_charts/` - Phase 3 charts from before the latest re-run

## Scripts

Scripts stay in this folder because they use relative paths. Run them from here.

| Script | What it does | Run with |
|---|---|---|
| `visualization_theme.R` | Shared blue theme for R scripts | sourced automatically |
| `viz_theme.py` | Python version of the blue theme | imported automatically |
| `Suhan_vehicle_analysis_Refactored.R` | Cleaning, market analysis, 8 charts, 5 summary CSVs | RStudio |
| `PredictionAndCode_Refactored.R` | ML demand models (Linear, Tree, RF, XGBoost, NN), rankings, comparison table | RStudio |
| `phase_3_forecasting_refactored.py` | ARIMA vs XGBoost on total monthly transfers, 6-month forecast. Reports multi-step and 1-step errors. | `python phase_3_forecasting_refactored.py` |
| `phase4_recommendations_refactored.py` | New vs used split, makes and models to stock, trending now | `python phase4_recommendations_refactored.py` |

Inputs for the Python scripts are in `../outputs/CSVs/` (made by `export_cleaned_records.R` and `export_timeseries_simple.R` in the project root).

## Phase 3 notes (for the slides)

- Backtest chart shows the last 12 months of training data, actual test values, and the multi-step ARIMA and XGBoost forecasts. The 1-step results are in the comparison table and bar chart.
- ARIMA uses order (1,1,1) with a seasonal term (1,0,0,12), set in `Config`.
- The future 6-month forecast uses the best multi-step model (currently XGBoost).
