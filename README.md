# CMCE30005 Business Analytics Challenge: Final Report

**Subject:** CMCE30005 Business Analytics Challenge, Semester 2 2026
**University:** University of Melbourne
**Team (Group 8):** Sabrina Nguyen, Thomas Haikal, Rutvi Tolani, Suhan Wang
**Last updated:** 15 October 2026

---

## Project Summary

We analyse Australian vehicle registrations and transfers (May 2023 to mid 2026) for a Queensland dealership group expanding into Melbourne. The client needs to:
- split investment between new and used stock
- pick which makes and models to prioritise in each segment
- avoid overstocking slow movers

The analysis runs in four phases, from raw data to stocking recommendations. Everything for the report is in `final report/`; its `README.md` lists every file.

```
Raw data → Phase 1 Cleaning → Phase 2 Market analysis → Phase 3 Predictive modelling → Phase 4 Recommendations
```

---

## Phase 1: Data Cleaning and Standardisation

**Goal:** turn the raw files into one consistent dataset.

| Input (`Raw_Datasets/`) | Description |
|---|---|
| `monthly_new_vehicle_registration_may2023_2026.csv` | New vehicle registrations by make/model |
| `monthly_vehicle_transfers_may2023_2026.csv` | Used vehicle transfers by make/model |
| `complete_vehicle_mapping.csv` | 862 make standardisation mappings |

**Steps**
1. Pre-clean vehicle codes (spacing, capitalisation, special characters).
2. Join the 862-make mapping table.
3. Fuzzy-match any remaining unknown codes (Levenshtein distance, 0.7+ threshold). Under 5% of codes stay unmatched.
4. Keep vehicles from 2010 onwards, drop missing models, keep makes and models making up the top 95% of market share.
5. Add vehicle age as a feature.
6. Export cleaned records and the monthly time series for the Python phases.

**Scripts:** `final report/Suhan_vehicle_analysis_Refactored.R` (cleaning and standardisation section), `export_cleaned_records.R`, `export_timeseries_simple.R`
**Output:** `outputs/CSVs/` (`transfers_cleaned_records.csv`, `registrations_cleaned_records.csv`, `transfers_cleaned_timeseries.csv`)
**Coverage after cleaning:** about 1M transfers and 155k new registrations.

---

## Phase 2: Market Analysis

**Goal:** describe the current market and its trends.

- Monthly transfer volume and seasonality
- Top 15 makes and top 20 models by transfers, with market share
- Year-over-year growth in new registrations and 12-month momentum by model
- Vehicle age distribution and age mix by make
- Growth vs popularity by model

**Script:** `final report/Suhan_vehicle_analysis_Refactored.R`
**Outputs:** 8 charts in `final report/Graphs/R_Plots_PDF/` and 5 summary tables in `final report/Data_Outputs/CSV/` (`01_transfer_make_summary.csv` to `05_top_20_models.csv`)

**Findings**
- Top 15 makes account for about 80% of transfers.
- The average transferred vehicle is 7 to 9 years old.
- Registration volume peaks in Q1 and Q4.
- Toyota is the largest make in used transfers (15.3% share), followed by Ford (8.7%).

---

## Phase 3: Predictive Modelling

Two models answer two questions: which makes and models will change most, and where total market volume is heading.

### 3a. Make and model demand (R)

Linear regression, decision tree, random forest, XGBoost and a neural net predict the 6-month change in demand for every make and model.

**Script:** `final report/PredictionAndCode_Refactored.R`
**Outputs:** `final report/Data_Outputs/CSV/linear_change_ranking.csv`, `rf_change_ranking.csv`, ranking charts in `final report/Graphs/R_Plots_PDF/`, and `final report/Reports/model_performance_comparison.html`

| Model | MAE | RMSE |
|---|---|---|
| Linear Regression | 18.61 | 60.14 |
| Random Forest | 18.76 | 65.94 |
| Baseline | 24.50 | 81.03 |
| XGBoost | 20.78 | 82.02 |
| Decision Tree | 94.19 | 198.73 |

**Findings:** electric vehicles show the largest predicted change in demand. Top of the random forest ranking: Ford Ranger, Tesla Model Y RWD and BYD Sealion. The linear model ranks Tesla Model Y LR, BYD Sealion and Tesla Model Y RWD highest.

### 3b. Total-market forecast (Python)

ARIMA vs XGBoost on monthly total transfers. The data is split 70/30 into train and test, and the better model is refit on all data to forecast the next 6 months.

**Script:** `final report/phase_3_forecasting_refactored.py`
**Outputs:** `final report/outputs/results/phase3_model_comparison.csv`, `final report/outputs/forecasts/phase3_forecast_6m.csv`, 3 charts in `final report/outputs/forecasts/charts/`

| Model | MAE | RMSE |
|---|---|---|
| XGBoost (multi-step) | 5,026 | 5,819 |
| XGBoost (1-step ahead) | 5,661 | 6,318 |
| ARIMA (1-step ahead) | 8,163 | 10,200 |
| ARIMA (multi-step) | 9,609 | 12,245 |

- XGBoost has the lowest error on every version and produces the 6-month forecast.
- ARIMA(1,1,1) with a seasonal term (1,0,0,12) is the baseline. Over a long horizon it flattens towards the last level.
- "1-step" predicts each month from the actual previous months. "Multi-step" predicts the whole test window from the end of training. The two are not like-for-like.

---

## Phase 4: Stocking Recommendations

**Goal:** turn the analysis into what to stock. This phase is descriptive, with no scoring.

1. **New vs used split:** over the last 12 months used transfers were 81.4% of volume and new registrations 18.6% (previous 12 months: 81.8% / 18.2%).
2. **Makes to stock, new cars:** share, year-over-year change and trend per make. Toyota (13.6%) and Ford (7.7%) lead but are down about 10% year on year, while BYD (7.0%) is up 171%.
3. **Makes and models to stock, used cars:** Toyota (15.5%), Ford (8.3%) and Mazda (7.6%) lead. Toyota, Ford and Holden are trending down, and Mazda and Hyundai are flat.
4. **Popular transfers right now** (last 3 months).
5. **Popular new registrations right now** (last 3 months): Toyota, BYD, Ford, Kia, Hyundai.

**Script:** `final report/phase4_recommendations_refactored.py`
**Outputs:** `phase4_*.csv` in `final report/outputs/forecasts/` and charts in `final report/Graphs/Python_Charts_PNG/`

---

## Running the Pipeline

Run in this order. Python scripts and R scripts in `final report/` use relative paths, so run them from inside that folder.

```r
# Phase 1: cleaned data (from project root)
setwd("~/Project_Group_8_CMCE30005")
source("export_cleaned_records.R")
source("export_timeseries_simple.R")

# Phases 1-3a (from final report/)
setwd("~/Project_Group_8_CMCE30005/final report")
source("Suhan_vehicle_analysis_Refactored.R")
source("PredictionAndCode_Refactored.R")
```
```
# Phases 3b and 4 (Terminal, inside final report/)
python phase_3_forecasting_refactored.py
python phase4_recommendations_refactored.py
```

R packages: dplyr, tidyverse, lubridate, quantmod, tidyr, ggplot2, scales, gt, stringdist.
Python packages: pandas, numpy, matplotlib, scikit-learn, statsmodels, xgboost.

---

## Contact

For questions about the analysis or methodology, contact the team via the University of Melbourne CMCE30005 channel.
