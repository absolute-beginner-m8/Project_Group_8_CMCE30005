# CMCE30005 Business Analytics Challenge
## Project_Group_8_CMCE30005 - Australian Vehicle Market Analysis

**Subject:** CMCE30005 Business Analytics Challenge, Semester 2 2026  
**University:** University of Melbourne  
**Team Members:** Sabrina Nguyen, Thomas Haikal, Rutvi Tolani, Suhan Wang

---

## Business Problem

Analyze the Australian vehicle registration and transfer market 
(May 2023 - 2026) to identify market trends, dominant vehicle makes/models, 
growth patterns, and age-based valuation signals. 
This analysis supports market forecasting and vehicle pricing strategy 
for stakeholders in the automotive industry.

---

## Dataset

**Dataset name:** Australian Monthly Vehicle Registration & Transfers (May 2023 - 2026)  
**Source:** Australian vehicle registration records  
**Coverage:** New vehicle registrations and used vehicle transfers across Australia

### Data Files

| File | Description | Size |
|------|-------------|------|
| `monthly_new_vehicle_registration_may2023_2026.csv` | New vehicle registrations by make/model | ~4.9 MB |
| `monthly_vehicle_transfers_may2023_2026.csv` | Used vehicle transfers by make/model | ~32.9 MB |
| `complete_vehicle_mapping.csv` | 862 vehicle make standardization mappings | ~19.2 KB |

**Note:** Data files are stored locally in `Raw_Datasets/` folder. Not committed to GitHub due to size.

---

## Analysis Overview

### Completed Work

**Data Cleaning & Standardization**
- Pre-cleaning of vehicle codes (spacing, capitalization, special characters)
- 862-make reference mapping for standardization
- Fuzzy matching for typo resolution (Levenshtein distance, 0.7+ threshold)

**Market Analysis**
- Top 15 vehicle makes by transfer volume
- Top 20 vehicle models ranking
- Market share calculations
- Year-over-year growth analysis

**Visualizations** (8 PDFs)
1. Monthly transfer volume trends
2. Top 15 makes ranking
3. Top 20 models ranking
4. Top 5 models trend lines
5. Growth vs popularity scatter plot
6. Vehicle age distribution
7. Age composition by make
8. New vehicle registration trends

**Summary Reports** (5 CSVs)
1. Transfer market share by make (avg age, model count)
2. New vehicle market share by make
3. Model growth analysis (12-month momentum)
4. Year-over-year registration data
5. Top 20 models ranking

---

## File Structure

```
Project_Group_8_CMCE30005/
├── R scripts/
│   └── Suhan_vehicle_analysis.R          # Main analysis workflow
├── Raw_Datasets/                         # Raw data (local only, not on GitHub)
│   ├── monthly_new_vehicle_registration_may2023_2026.csv
│   ├── monthly_vehicle_transfers_may2023_2026.csv
│   └── complete_vehicle_mapping.csv
├── outputs/
│   ├── PDFs/                             # 8 visualizations
│   │   ├── 01_monthly_transfers.pdf
│   │   ├── 02_top_makes.pdf
│   │   └── ... (6 more)
│   └── CSVs/                             # 5 summary reports
│       ├── 01_transfer_make_summary.csv
│       ├── 02_new_vehicle_summary.csv
│       └── ... (3 more)
├── README.md
└── .gitignore
```

---

## How to Use

### Prerequisites

Install R packages:
```r
install.packages(c("dplyr", "tidyverse", "lubridate", "quantmod", 
                   "tidyr", "ggplot2", "scales", "gt", "stringdist"))
```

### Running the Analysis

1. **Get the data files:**
   - Place `monthly_new_vehicle_registration_may2023_2026.csv`
   - Place `monthly_vehicle_transfers_may2023_2026.csv`
   - Place `complete_vehicle_mapping.csv`
   - All in `Raw_Datasets/` folder

2. **Run the script:**
   ```r
   setwd("~/Project_Group_8_CMCE30005")
   source("R scripts/Suhan_vehicle_analysis.R")
   ```

3. **Access outputs:**
   - PDFs: `outputs/PDFs/`
   - CSVs: `outputs/CSVs/`

---

## Key Findings

- **Market concentration:** Top 15 makes account for ~80% of transfers
- **Growth trends:** Electric vehicles and Asian brands showing strong momentum
- **Age profile:** Average transfer vehicle age is 7-9 years (depreciation signal)
- **Seasonality:** Registration volume peaks in specific months (Q1/Q4 patterns)

---

## Technical Notes

- **Data cleaning pipeline:** Raw code standardization → mapping table join → fuzzy matching for unknowns
- **Coverage:** Vehicles manufactured 2010+, top 95% market share makes (removes niche outliers)
- **Records processed:** ~1M transfers + ~155k new registrations
- **Unmatched codes:** <5% after standardization & fuzzy matching

---

*Last updated: 29 August 2026*
