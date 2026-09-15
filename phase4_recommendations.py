"""
PHASE 4: INVESTMENT RECOMMENDATIONS ALGORITHM
==============================================

Generates investment scores (0-100) and ratings (Accumulate/Hold/Reduce)
for each vehicle make based on market data.

SCORING METHODOLOGY:
- 5 weighted factors contribute to final score
- Scores 45-100: ACCUMULATE (Strong Buy)
- Scores 30-44: HOLD (Neutral)  
- Scores 0-29: REDUCE (Sell)
"""

import pandas as pd
import numpy as np
from pathlib import Path

# ============================================================================
# CONFIGURATION: INVESTMENT SCORING WEIGHTS
# ============================================================================

class InvestmentScoring:
    """
    Investment scoring algorithm with configurable weights.
    
    Weights (must sum to 100%):
    - Growth Momentum: 35% (Year-over-year growth rate)
    - Market Volume: 25% (Total market size / liquidity)
    - Consistency: 15% (Stability of transfers over time)
    - Age Health: 15% (Average vehicle age in fleet)
    - Market Share: 10% (Percentage of total market)
    """
    
    WEIGHTS = {
        'growth_momentum': 0.35,      # 35% - Most important factor
        'market_volume': 0.25,        # 25% - Liquidity/size matters
        'consistency': 0.15,          # 15% - Stability valued
        'age_health': 0.15,           # 15% - Fleet quality
        'market_share': 0.10          # 10% - Market dominance
    }
    
    # ========================================================================
    # INVESTMENT RATING BRACKETS
    # ========================================================================
    
    RATING_BRACKETS = {
        'accumulate': {'min': 45, 'max': 100, 'signal': 'STRONG BUY'},
        'hold': {'min': 30, 'max': 44, 'signal': 'NEUTRAL/WAIT'},
        'reduce': {'min': 0, 'max': 29, 'signal': 'SELL/AVOID'}
    }
    
    @staticmethod
    def calculate_score(growth, volume, consistency, age, market_share):
        """
        Calculate composite investment score.
        
        Args:
            growth (float): Growth momentum score (0-100)
            volume (float): Market volume score (0-100)
            consistency (float): Consistency score (0-100)
            age (float): Age health score (0-100)
            market_share (float): Market share score (0-100)
        
        Returns:
            float: Composite investment score (0-100)
        
        Formula:
        Score = (35% × Growth) + (25% × Volume) + (15% × Consistency) 
                + (15% × Age) + (10% × Market Share)
        """
        score = (
            InvestmentScoring.WEIGHTS['growth_momentum'] * growth +
            InvestmentScoring.WEIGHTS['market_volume'] * volume +
            InvestmentScoring.WEIGHTS['consistency'] * consistency +
            InvestmentScoring.WEIGHTS['age_health'] * age +
            InvestmentScoring.WEIGHTS['market_share'] * market_share
        )
        return round(score, 1)
    
    @staticmethod
    def get_rating(score):
        """
        Determine investment rating based on score.
        
        Args:
            score (float): Investment score (0-100)
        
        Returns:
            tuple: (rating_label, signal_description)
        
        BRACKETS:
        - 45-100: ACCUMULATE (Strong Buy) — Build position
        - 30-44: HOLD (Neutral) — Monitor, don't buy yet
        - 0-29: REDUCE (Sell) — Exit position
        """
        if score >= InvestmentScoring.RATING_BRACKETS['accumulate']['min']:
            return 'Accumulate', InvestmentScoring.RATING_BRACKETS['accumulate']['signal']
        elif score >= InvestmentScoring.RATING_BRACKETS['hold']['min']:
            return 'Hold', InvestmentScoring.RATING_BRACKETS['hold']['signal']
        else:
            return 'Reduce', InvestmentScoring.RATING_BRACKETS['reduce']['signal']


# ============================================================================
# LOAD DATA FROM PHASE 3
# ============================================================================

print("="*80)
print("PHASE 4: INVESTMENT RECOMMENDATIONS SCORING")
print("="*80)

print("\n📥 Loading forecast data from Phase 3...")
forecast_df = pd.read_csv('outputs/forecasts/phase3_forecast_12m.csv')

# Load cleaned records for make-level aggregation
print("📥 Loading cleaned transfer records...")
transfers_clean = pd.read_csv('outputs/CSVs/transfers_cleaned_records.csv')

# Convert to datetime
transfers_clean['data_month_year'] = pd.to_datetime(transfers_clean['data_month_year'])

print(f"✓ Loaded {len(transfers_clean):,} transfer records")
print(f"✓ Loaded {len(forecast_df)} month forecasts")


# ============================================================================
# CALCULATE FACTOR SCORES BY MAKE
# ============================================================================

print("\n" + "="*80)
print("CALCULATING INVESTMENT SCORES")
print("="*80)

# Get latest 12 months
latest_date = transfers_clean['data_month_year'].max()
twelve_months_ago = latest_date - pd.DateOffset(months=12)
twenty_four_months_ago = latest_date - pd.DateOffset(months=24)

recent_12m = transfers_clean[
    transfers_clean['data_month_year'] > twelve_months_ago
].groupby('make_standard')['TOTAL'].sum()

previous_12m = transfers_clean[
    (transfers_clean['data_month_year'] > twenty_four_months_ago) &
    (transfers_clean['data_month_year'] <= twelve_months_ago)
].groupby('make_standard')['TOTAL'].sum()

all_time = transfers_clean.groupby('make_standard')['TOTAL'].sum()

# Calculate factors
scores = []

for make in all_time.index:
    # ====================================================================
    # FACTOR 1: GROWTH MOMENTUM (35%)
    # ====================================================================
    # Year-over-year growth rate
    
    recent = recent_12m.get(make, 0)
    previous = previous_12m.get(make, 0)
    
    if previous > 0:
        growth_pct = ((recent - previous) / previous) * 100
    else:
        growth_pct = 0
    
    # Normalize growth to 0-100 scale (-50% to +50% → 0-100)
    growth_score = min(100, max(0, 50 + (growth_pct * 0.5)))
    
    # ====================================================================
    # FACTOR 2: MARKET VOLUME (25%)
    # ====================================================================
    # Total market size = liquidity
    
    total_volume = all_time[make]
    max_volume = all_time.max()
    volume_score = (total_volume / max_volume) * 100
    
    # ====================================================================
    # FACTOR 3: CONSISTENCY (15%)
    # ====================================================================
    # Low volatility over time = stable demand
    
    make_timeseries = transfers_clean[
        transfers_clean['make_standard'] == make
    ].groupby('data_month_year')['TOTAL'].sum()
    
    if len(make_timeseries) > 1:
        cv = make_timeseries.std() / make_timeseries.mean()  # Coefficient of variation
        consistency_score = min(100, max(0, 100 - (cv * 50)))  # Lower CV = higher score
    else:
        consistency_score = 50
    
    # ====================================================================
    # FACTOR 4: AGE HEALTH (15%)
    # ====================================================================
    # Average vehicle age (younger = more valuable)
    # Placeholder: use recent volume as proxy (high volume = healthier fleet)
    
    age_score = min(100, (recent / max(recent_12m.values)) * 100) if len(recent_12m) > 0 else 50
    
    # ====================================================================
    # FACTOR 5: MARKET SHARE (10%)
    # ====================================================================
    # Percentage of total market
    
    market_share_pct = (total_volume / transfers_clean['TOTAL'].sum()) * 100
    market_share_score = market_share_pct * 2  # Scale up to 0-100
    
    # ====================================================================
    # CALCULATE COMPOSITE SCORE
    # ====================================================================
    
    composite_score = InvestmentScoring.calculate_score(
        growth=growth_score,
        volume=volume_score,
        consistency=consistency_score,
        age=age_score,
        market_share=market_share_score
    )
    
    rating, signal = InvestmentScoring.get_rating(composite_score)
    
    scores.append({
        'make_standard': make,
        'total_volume': int(total_volume),
        'recent_12m': int(recent),
        'previous_12m': int(previous),
        'growth_pct': round(growth_pct, 1),
        'growth_score': round(growth_score, 1),
        'volume_score': round(volume_score, 1),
        'consistency_score': round(consistency_score, 1),
        'age_health_score': round(age_score, 1),
        'market_share_pct': round(market_share_pct, 2),
        'market_share_score': round(market_share_score, 1),
        'investment_score': composite_score,
        'rating': rating,
        'signal': signal
    })

scores_df = pd.DataFrame(scores).sort_values('investment_score', ascending=False)

# ============================================================================
# DISPLAY RESULTS
# ============================================================================

print("\n" + "-"*80)
print("INVESTMENT SCORES & RATINGS")
print("-"*80)

display_cols = ['make_standard', 'investment_score', 'rating', 'total_volume', 'growth_pct']
print(scores_df[display_cols].to_string(index=False))

# ============================================================================
# DETAILED BREAKDOWN FOR TOP MAKES
# ============================================================================

print("\n" + "="*80)
print("DETAILED FACTOR BREAKDOWN (Top 5 Makes)")
print("="*80)

for i, row in scores_df.head(5).iterrows():
    print(f"\n{row['make_standard']} (Score: {row['investment_score']})")
    print(f"  ├─ Growth Momentum (35%): {row['growth_score']:.1f} (YoY: {row['growth_pct']:+.1f}%)")
    print(f"  ├─ Market Volume (25%): {row['volume_score']:.1f} (Total: {row['total_volume']:,})")
    print(f"  ├─ Consistency (15%): {row['consistency_score']:.1f}")
    print(f"  ├─ Age Health (15%): {row['age_health_score']:.1f}")
    print(f"  └─ Market Share (10%): {row['market_share_score']:.1f} ({row['market_share_pct']:.2f}%)")
    print(f"  📊 RATING: {row['rating']} → {row['signal']}")

# ============================================================================
# SAVE RESULTS
# ============================================================================

print("\n" + "="*80)
print("SAVING RESULTS")
print("="*80)

output_file = Path('outputs/forecasts/phase4_recommendations_scored.csv')
scores_df.to_csv(output_file, index=False)
print(f"✓ Saved: {output_file}")

# Create summary
summary = {
    'Total Makes Analyzed': len(scores_df),
    'Accumulate (45+)': len(scores_df[scores_df['investment_score'] >= 45]),
    'Hold (30-44)': len(scores_df[(scores_df['investment_score'] >= 30) & (scores_df['investment_score'] < 45)]),
    'Reduce (<30)': len(scores_df[scores_df['investment_score'] < 30]),
    'Average Score': round(scores_df['investment_score'].mean(), 1),
}

print("\n" + "="*80)
print("SUMMARY")
print("="*80)
for key, val in summary.items():
    print(f"{key}: {val}")

print("\n" + "="*80)
print("PHASE 4 COMPLETE ✓")
print("="*80)
print("\nOutput files:")
print(f"  ✓ {output_file}")
print("\nNext: Use scores_df to generate visualizations (02_recommendations.png)")