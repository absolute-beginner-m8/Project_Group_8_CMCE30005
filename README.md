# CMCE30005 Business Analytics Challenge: Australian Vehicle Market Analysis

**Subject:** CMCE30005 Business Analytics Challenge, Semester 2 2026  
**University:** University of Melbourne  
**Team:** Sabrina Nguyen, Thomas Haikal, Rutvi Tolani, Suhan Wang  
**Last Updated:** August 2026

---

## Overview

This project analyzes the Australian vehicle registration and transfer market (May 2023–2026) to identify market trends, dominant makes/models, growth patterns, and age-based valuation signals. The analysis supports strategic inventory planning and pricing decisions for automotive stakeholders expanding into unfamiliar markets.

---

## Business Problem

Our client operates multiple Queensland dealerships and is expanding into Melbourne. They need to:
- Decide how to split investment between new-vehicle and used-vehicle stock
- Identify which makes/models to prioritize in each segment
- Maximize inventory turnover and avoid overstocking slow-moving segments

---

## Data

| File | Description | Size |
|------|-------------|------|
| `monthly_new_vehicle_registration_may2023_2026.csv` | New vehicle registrations by make/model | ~4.9 MB |
| `monthly_vehicle_transfers_may2023_2026.csv` | Used vehicle transfers by make/model | ~32.9 MB |
| `complete_vehicle_mapping.csv` | 862 vehicle make standardization mappings | ~19.2 KB |

**Location:** Raw_Datasets/ folder (local only, not committed to GitHub due to size)  
**Coverage:** ~1M transfers + ~155k new registrations (2010+ models, top 95% market share)

---

## What's Included

### Data Cleaning & Standardization
- Pre-cleaning of vehicle codes (spacing, capitalization, special characters)
- 862-make reference mapping for consistency
- Fuzzy matching for typo resolution (Levenshtein distance, 0.7+ threshold)
- <5% unmatched codes after processing

### Market Analysis
- Top 15 vehicle makes by transfer volume
- Top 20 vehicle models ranking
- Market share calculations
- Year-over-year growth analysis
- Seasonality patterns in registrations

### Outputs

**8 PDF Visualizations:**
1. Monthly transfer volume trends
2. Top 15 makes ranking
3. Top 20 models ranking
4. Top 5 models trend lines
5. Growth vs popularity scatter plot
6. Vehicle age distribution
7. Age composition by make
8. New vehicle registration trends
9. Linear regression rankings
10. Random forest rankings

**5 CSV Summary Reports:**
1. Transfer market share by make (avg age, model count)
2. New vehicle market share by make
3. Model growth analysis (12-month momentum)
4. Year-over-year registration data
5. Top 20 models ranking
6. Linear regression full list of change in demand (all makes and models)
7. Random forest full list of change in demand (all makes and models)

Outputs saved to `outputs/` and `Output_results/` folder.


---

## Quick Start

### Prerequisites
Install R packages:
```r
install.packages(c("dplyr", "tidyverse", "lubridate", "quantmod",
                   "tidyr", "ggplot2", "scales", "gt", "stringdist"))
```

### Run Analysis
```r
setwd("~/Project_Group_8_CMCE30005")
source("R scripts/Suhan_vehicle_analysis.R")
```

This will:
1. Load and clean raw datasets
2. Apply standardization mappings
3. Generate all visualizations (PDFs)
4. Export summary reports (CSVs)

**Outputs location:** `outputs/PDFs/` and `outputs/CSVs/`

---

## Key Findings

- **Market concentration:** Top 15 makes account for ~80% of transfers
- **Growth trends:** Electric vehicles and Asian brands showing strong momentum
- **Age profile:** Average transfer vehicle is 7–9 years old (key depreciation signal)
- **Seasonality:** Registration volume peaks in Q1 and Q4
- **Model diversity:** Top 20 models represent ~40% of market, indicating strong tail
- **Change in demand:** We can see that electric cars are predicted to have largest change in demand in the next 6 months 

---

## File Structure

```
Project_Group_8_CMCE30005/
├── R scripts/
│   └── Suhan_vehicle_analysis.R          # Main analysis pipeline
├── Raw_Datasets/                         # Raw data (local only)
│   ├── monthly_new_vehicle_registration_may2023_2026.csv
│   ├── monthly_vehicle_transfers_may2023_2026.csv
│   └── complete_vehicle_mapping.csv
├── outputs/
│   ├── PDFs/                             # 8 visualizations
│   └── CSVs/                             # 5 summary reports
├── Presentation/                         # Presentation slides
├── Test_Folder/
│   ├── AnalyticsPart.R                   # Look at 6 month future predicted demand         
│   └── PredictionAndCode.R               # Look at 6 month future predicted demand
├── Output_results/                       # Output of the change in demand as a csv for both linear and random forests
│   ├── linear_change_ranking.csv
│   ├── rf_change_ranking.csv
├── README.md
├── requirements.txt
└── .gitignore
```

---

## Technical Notes

- **Data cleaning pipeline:** Raw code standardization → mapping table join → fuzzy matching for unknowns
- **Coverage:** Vehicles manufactured 2010+, top 95% market share makes and models (outliers removed)
- **Language:** R (data manipulation, visualization, time-series analysis, linear regression, random forest)
- **Matching accuracy:** >95% after standardization and fuzzy matching

---

## Running Individual Scripts

The project uses a modular R structure. Key scripts:

- `R scripts/Suhan_vehicle_analysis.R` — Main analysis workflow
- `export_cleaned_records.R` — Export cleaned datasets
- `export_timeseries_simple.R` — Time-series data export
- `fix_columns.R` — Column structure fixes
- `PredictionAndCode.R` — Predictive modeling for make and model (Phase 3)

For Python forecasting:
- `phase_3_forecasting.py` — ARIMA/Prophet forecasting
- `phase4_recommendations.py` — Strategic recommendations

---

## Contact

For questions about the analysis or methodology, contact the team via the University of Melbourne CMCE30005 channel.

Last updated: 17th Sep 2026
