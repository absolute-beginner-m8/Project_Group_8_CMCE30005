"""
PHASE 3: PREDICTIVE MODELING - CLEAN VERSION
Vehicle Transfer Volume Forecasting (ARIMA + XGBoost)
"""

import pandas as pd
import numpy as np
import warnings
from pathlib import Path
from datetime import datetime
import json

warnings.filterwarnings('ignore')

# Time series
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.stattools import adfuller

# ML
from sklearn.metrics import mean_absolute_error, mean_squared_error, mean_absolute_percentage_error
import xgboost as xgb

# ============================================================================
# CONFIG
# ============================================================================

class Config:
    RAW_DATA_DIR = Path("Raw_Datasets")
    RAW_TRANSFERS_FILE = RAW_DATA_DIR / "monthly_vehicle_transfers_may2023_2026.csv"
    
    OUTPUT_DIR = Path("outputs/forecasts")
    RESULTS_DIR = Path("outputs/results")
    PLOTS_DIR = Path("outputs/plots")
    
    FORECAST_HORIZON = 12
    TEST_SPLIT = 0.7
    TOP_N_MAKES = 5
    
    @classmethod
    def setup_directories(cls):
        for directory in [cls.OUTPUT_DIR, cls.RESULTS_DIR, cls.PLOTS_DIR]:
            directory.mkdir(parents=True, exist_ok=True)

# ============================================================================
# DATA LOADING
# ============================================================================

def load_data():
    """Load raw monthly transfers and aggregate"""
    print(f"📥 Loading data...")
    
    df = pd.read_csv(Config.RAW_TRANSFERS_FILE)
    df['date'] = pd.to_datetime(df['data_month_year'], format='%Y%m')
    
    # Aggregate to monthly totals
    monthly = df.groupby('date')['TOTAL'].sum().sort_index()
    
    print(f"✓ Loaded transfers: {len(df):,} records")
    print(f"  Monthly observations: {len(monthly)}")
    print(f"  Date range: {monthly.index.min().date()} to {monthly.index.max().date()}")
    
    return monthly, df

# ============================================================================
# MODEL 1: ARIMA
# ============================================================================

class ARIMAForecaster:
    def __init__(self):
        self.model = None
        self.fitted = None
        self.order = (1, 1, 1)
    
    def fit(self, train_series):
        """Fit ARIMA"""
        print("\n1️⃣  ARIMA")
        self.model = ARIMA(train_series, order=self.order)
        self.fitted = self.model.fit()
        print(f"  ✓ ARIMA{self.order} fitted")
        return self.fitted
    
    def forecast(self, steps):
        """Generate forecast"""
        forecast_result = self.fitted.get_forecast(steps=steps)
        forecast = forecast_result.predicted_mean
        conf_int = forecast_result.conf_int()
        return forecast, conf_int

# ============================================================================
# MODEL 2: XGBOOST
# ============================================================================

class XGBoostForecaster:
    def __init__(self):
        self.model = None
    
    @staticmethod
    def create_lag_features(series, lags=[1, 3, 6, 12]):
        """Create lagged features"""
        data = series.values
        X, y = [], []
        
        for i in range(len(series) - max(lags)):
            features = [data[i + max(lags) - lag] for lag in lags]
            target = data[i + max(lags)]
            X.append(features)
            y.append(target)
        
        return np.array(X), np.array(y)
    
    def fit(self, train_series):
        """Fit XGBoost"""
        print("\n2️⃣  XGBOOST")
        X, y = self.create_lag_features(train_series)
        
        self.model = xgb.XGBRegressor(
            n_estimators=200,
            max_depth=5,
            learning_rate=0.05,
            random_state=42
        )
        self.model.fit(X, y, verbose=False)
        print(f"  ✓ XGBoost fitted ({len(X)} training samples)")
        return self.model
    
    def forecast(self, series, steps):
        """Forecast recursively"""
        forecast = []
        history = series.copy()
        
        for _ in range(steps):
            lags = [1, 3, 6, 12]
            features = np.array([[history.values[-(lag)] for lag in lags]])
            pred = self.model.predict(features)[0]
            forecast.append(pred)
            
            history = pd.concat([
                history,
                pd.Series([pred], index=[history.index[-1] + pd.DateOffset(months=1)])
            ])
        
        return np.array(forecast)

# ============================================================================
# MAIN
# ============================================================================

def main():
    Config.setup_directories()
    
    print("="*70)
    print("PHASE 3: PREDICTIVE MODELING")
    print("="*70)
    
    # Load data
    monthly_series, transfers_df = load_data()
    
    # Split data
    split_point = int(len(monthly_series) * Config.TEST_SPLIT)
    train_series = monthly_series[:split_point]
    test_series = monthly_series[split_point:]
    
    print("\n" + "="*70)
    print("TRAINING MODELS")
    print("="*70)
    
    results = {}
    
    # Train ARIMA
    try:
        arima = ARIMAForecaster()
        arima.fit(train_series)
        arima_pred, arima_ci = arima.forecast(len(test_series))
        
        arima_mae = mean_absolute_error(test_series, arima_pred)
        arima_rmse = np.sqrt(mean_squared_error(test_series, arima_pred))
        arima_mape = mean_absolute_percentage_error(test_series, arima_pred)
        
        results['ARIMA'] = {
            'model': arima,
            'mae': arima_mae,
            'rmse': arima_rmse,
            'mape': arima_mape,
            'pred': arima_pred
        }
        print(f"  ✓ MAE: {arima_mae:.0f} | RMSE: {arima_rmse:.0f} | MAPE: {arima_mape:.2%}")
    except Exception as e:
        print(f"  ✗ ARIMA failed: {e}")
    
    # Train XGBoost
    try:
        xgb_model = XGBoostForecaster()
        xgb_model.fit(train_series)
        xgb_pred = xgb_model.forecast(train_series, len(test_series))
        
        xgb_mae = mean_absolute_error(test_series, xgb_pred)
        xgb_rmse = np.sqrt(mean_squared_error(test_series, xgb_pred))
        xgb_mape = mean_absolute_percentage_error(test_series, xgb_pred)
        
        results['XGBoost'] = {
            'model': xgb_model,
            'mae': xgb_mae,
            'rmse': xgb_rmse,
            'mape': xgb_mape,
            'pred': xgb_pred
        }
        print(f"  ✓ MAE: {xgb_mae:.0f} | RMSE: {xgb_rmse:.0f} | MAPE: {xgb_mape:.2%}")
    except Exception as e:
        print(f"  ✗ XGBoost failed: {e}")
    
    # Select best model
    print("\n" + "="*70)
    print("MODEL COMPARISON")
    print("="*70)
    
    comparison = []
    for model_name, data in results.items():
        comparison.append({
            'Model': model_name,
            'MAE': round(data['mae'], 0),
            'RMSE': round(data['rmse'], 0),
            'MAPE': f"{data['mape']:.2%}"
        })
    
    comparison_df = pd.DataFrame(comparison).sort_values('MAE')
    print("\n" + comparison_df.to_string(index=False))
    comparison_df.to_csv(Config.RESULTS_DIR / 'phase3_model_comparison.csv', index=False)
    
    best_model_name = comparison_df.iloc[0]['Model']
    best_model_obj = results[best_model_name]['model']
    
    # Generate future forecast
    print("\n" + "="*70)
    print(f"FUTURE FORECAST ({Config.FORECAST_HORIZON} months)")
    print("="*70)
    
    if best_model_name == 'ARIMA':
        forecast, conf = best_model_obj.forecast(Config.FORECAST_HORIZON)
        conf_lower = conf.iloc[:, 0]
        conf_upper = conf.iloc[:, 1]
    elif best_model_name == 'XGBoost':
        forecast = best_model_obj.forecast(monthly_series, Config.FORECAST_HORIZON)
        conf_lower = forecast * 0.9
        conf_upper = forecast * 1.1
    
    future_dates = pd.date_range(
        start=monthly_series.index[-1] + pd.DateOffset(months=1),
        periods=Config.FORECAST_HORIZON,
        freq='MS'
    )
    
    forecast_df = pd.DataFrame({
        'date': future_dates,
        'forecast': forecast,
        'ci_lower': conf_lower,
        'ci_upper': conf_upper
    })
    
    print(f"\nUsing: {best_model_name}")
    print(forecast_df.to_string(index=False))
    forecast_df.to_csv(Config.OUTPUT_DIR / 'phase3_forecast_12m.csv', index=False)
    
    # Forecast by top makes
    print("\n" + "="*70)
    print("FORECAST BY TOP MAKES")
    print("="*70)
    
    transfers_df['make_clean'] = transfers_df['CD_MAKE_VEH'].str.strip()
    transfers_df['date'] = pd.to_datetime(transfers_df['data_month_year'], format='%Y%m')
    
    top_makes = transfers_df.groupby('make_clean')['TOTAL'].sum().nlargest(Config.TOP_N_MAKES)
    
    by_make_forecasts = []
    for make in top_makes.index:
        try:
            make_data = transfers_df[transfers_df['make_clean'] == make]
            make_monthly = make_data.groupby('date')['TOTAL'].sum().sort_index()
            
            if len(make_monthly) > 3:
                arima = ARIMAForecaster()
                arima.fit(make_monthly)
                make_forecast, _ = arima.forecast(Config.FORECAST_HORIZON)
                
                by_make_forecasts.append({
                    'make': make,
                    'current_avg': make_monthly.tail(12).mean(),
                    'forecast_avg': make_forecast.mean(),
                    'trend': 'Up' if make_forecast.mean() > make_monthly.tail(12).mean() else 'Down'
                })
                print(f"  {make:20} → {make_forecast.mean():.0f} avg (trend: {by_make_forecasts[-1]['trend']})")
        except:
            pass
    
    by_make_df = pd.DataFrame(by_make_forecasts)
    by_make_df.to_csv(Config.OUTPUT_DIR / 'phase3_forecast_by_make.csv', index=False)
    
    # Summary
    print("\n" + "="*70)
    print("PHASE 3 COMPLETE ✓")
    print("="*70)
    
    summary = {
        'execution_date': datetime.now().isoformat(),
        'data_period': f"{monthly_series.index.min().date()} to {monthly_series.index.max().date()}",
        'observations': len(monthly_series),
        'best_model': best_model_name,
        'best_model_mae': float(comparison_df.iloc[0]['MAE']),
        'forecast_horizon': Config.FORECAST_HORIZON,
        'files_created': [
            'phase3_model_comparison.csv',
            'phase3_forecast_12m.csv',
            'phase3_forecast_by_make.csv',
            'phase3_summary.json'
        ]
    }
    
    with open(Config.RESULTS_DIR / 'phase3_summary.json', 'w') as f:
        json.dump(summary, f, indent=2)
    
    print(f"\n✓ Files saved to outputs/forecasts/ and outputs/results/")
    print(f"✓ Summary: {Config.RESULTS_DIR / 'phase3_summary.json'}")

if __name__ == "__main__":
    main()
