# CMCE30005 Business Analytics Challenge: Australian Vehicle Market Analysis

**Subject:** CMCE30005 Business Analytics Challenge, Semester 2 2026
**University:** University of Melbourne
**Team (Group 8):** Sabrina Nguyen, Thomas Haikal, Rutvi Tolani, Suhan Wang
**Last updated:** 15 October 2026

---

## Overview

We analyse Australian vehicle registrations and transfers (May 2023 to mid 2026) to find market trends, dominant makes and models, and where demand is heading over the next 6 months. The results support stock planning for a dealership group.

The work has four stages:

1. **Clean and explore (R):** standardise make names, build market summaries and charts.
2. **Make/model demand ranking (R):** linear regression, decision tree, random forest, XGBoost (and a neural net) predict the 6-month change in demand for each make and model.
3. **Total-market forecast (Python):** ARIMA vs XGBoost on monthly total transfers, 6-month horizon.
4. **Recommendations (Python):** new vs used split, makes and models to stock, what is trending now.

The **final report material lives in `final report/`**. Start with `final report/README.md`.

---

## Business Problem

Our client runs Queensland dealerships and is expanding into Melbourne. They need to:
- Decide how to split investment between new and used stock
- Pick which makes and models to prioritise in each segment
- Maximise turnover and avoid overstocking slow movers

---

## Data

| File | Description | Size |
|------|-------------|------|
| `monthly_new_vehicle_registration_may2023_2026.csv` | New vehicle registrations by make/model | ~4.9 MB |
| `monthly_vehicle_transfers_may2023_2026.csv` | Used vehicle transfers by make/model | ~32.9 MB |
| `complete_vehicle_mapping.csv` | 862 make standardisation mappings | ~19.2 KB |

**Location:** `Raw_Datasets/` (local only, not committed to GitHub because of size)
**Coverage:** about 1M transfers and 155k new registrations (2010+ models, top 95% market share)

Cleaning: code pre-cleaning (spacing, case, special characters), the 862-make mapping, then fuzzy matching (Levenshtein, 0.7+ threshold). Under 5% of codes stay unmatched.

---

## Results So Far

**Total-market forecast (Phase 3, test set, monthly transfers)**

| Model | MAE | RMSE |
|---|---|---|
| XGBoost (multi-step) | 5,026 | 5,819 |
| XGBoost (1-step ahead) | 5,661 | 6,318 |
| ARIMA (1-step ahead) | 8,163 | 10,200 |
| ARIMA (multi-step) | 9,609 | 12,245 |

- XGBoost is best on every version, so it is used for the 6-month forecast.
- ARIMA is the baseline. Over a multi-step horizon it flattens towards the last level, and the sharp monthly swings are not predictable from past values alone.
- "1-step" means each month is predicted from the actual previous months. "Multi-step" predicts the whole test window from the end of training. The two are not like-for-like.

**Make/model demand models (R, test set):** Linear Regression has the lowest error (MAE 18.61, RMSE 60.14), then Random Forest (18.76, 65.94), Baseline (24.50), XGBoost (20.78) and Decision Tree (94.19). See `final report/Reports/model_performance_comparison.html`.

**New vs used (Phase 4):** over the last 12 months used transfers were 81.4% of volume and new registrations 18.6% (previous 12 months: 81.8% / 18.2%).

**Other findings (from the R analysis):**
- Top 15 makes account for about 80% of transfers
- Average transferred vehicle is 7 to 9 years old
- Registration volume peaks in Q1 and Q4
- Electric vehicles are predicted to show the largest change in demand over the next 6 months

---

## Folder Structure

```
Project_Group_8_CMCE30005/
├── final report/              # FINAL REPORT: scripts, charts, tables (see its README)
│   ├── Graphs/                #   R PDFs and Python PNGs used in the report
│   ├── Data_Outputs/CSV/      #   R result tables
│   ├── Reports/               #   model comparison table (HTML)
│   ├── outputs/               #   Python outputs (forecasts, results, charts)
│   ├── _archive/              #   old script versions, backups, previous charts
│   └── *.R, *.py              #   the scripts to run
├── Raw_Datasets/              # raw data (local only)
├── outputs/                   # cleaned datasets (CSVs/) and earlier outputs used as inputs
├── Output_results/            # demand-change rankings (linear, random forest)
├── Test_Folder/               # early exploration scripts and project brief
├── Presentation/              # project plan slides
├── export_cleaned_records.R   # writes outputs/CSVs/*_cleaned_records.csv
├── export_timeseries_simple.R # writes outputs/CSVs/transfers_cleaned_timeseries.csv
├── fix_columns.R
├── visualization_theme.R
├── requirements.txt
└── README.md
```

---

## How To Run

Run everything from the `final report/` folder, because the scripts use relative paths (`../Raw_Datasets`, `../outputs/CSVs`).

**1. Prepare cleaned data (R, from the project root)**
```r
setwd("~/Project_Group_8_CMCE30005")
source("export_cleaned_records.R")
source("export_timeseries_simple.R")
```

**2. R analysis (R / RStudio, working directory `final report/`)**
```r
setwd("~/Project_Group_8_CMCE30005/final report")
source("Suhan_vehicle_analysis_Refactored.R")   # cleaning, summaries, 8 charts
source("PredictionAndCode_Refactored.R")        # ML demand models and rankings
```
R packages: dplyr, tidyverse, lubridate, quantmod, tidyr, ggplot2, scales, gt, stringdist.

**3. Python (Terminal, inside `final report/`)**
```
pip install pandas numpy matplotlib scikit-learn statsmodels xgboost
python phase_3_forecasting_refactored.py
python phase4_recommendations_refactored.py
```

---

## Known Issues

- `PredictionAndCode_Refactored.R` (line 27) reads `monthly_transfers_may2023_2026.csv`, but the file is named `monthly_vehicle_transfers_may2023_2026.csv`. Fix the name before running.
- `requirements.txt` lists `fbprophet`, which the current scripts do not use (Phase 3 compares ARIMA and XGBoost).
- `final report/refactored_analysis_visualization.R` looks like an earlier copy of `Suhan_vehicle_analysis_Refactored.R`. Use the latter.

---

## Contact

For questions about the analysis or methodology, contact the team via the University of Melbourne CMCE30005 channel.
