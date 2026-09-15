import pandas as pd
import numpy as np
import warnings
from pathlib import Path
from datetime import datetime
import json

warnings.filterwarnings('ignore')

from statsmodels.tsa.arima.model import ARIMA
from sklearn.metrics import mean_absolute_error, mean_squared_error
import xgboost as xgb

class Config:
    OUTPUT_DIR = Path("outputs/forecasts")
    RESULTS_DIR = Path("outputs/results")
    FORECAST_HORIZON = 12
    TEST_SPLIT = 0.7
    
    @classmethod
    def setup_directories(cls):
        for directory in [cls.OUTPUT_DIR, cls.RESULTS_DIR]:
            directory.mkdir(parents=True, exist_ok=True)

def main():
    Config.setup_directories()
    
    print("="*70)
    print("PHASE 3: PREDICTIVE MODELING (CLEAN DATA)")
    print("="*70)
    
    print("\n📥 Loading cleaned time-series data...")
    df = pd.read_csv('outputs/CSVs/transfers_cleaned_timeseries.csv')
    df['date'] = pd.to_datetime(df['data_month_year'])
    monthly_series = df.set_index('date')['total_transfers'].sort_index()
    
    print(f"✓ Loaded: {len(monthly_series)} observations")
    print(f"  Date range: {monthly_series.index.min().date()} to {monthly_series.index.max().date()}")
    
    split_point = int(len(monthly_series) * Config.TEST_SPLIT)
    train_series = monthly_series[:split_point]
    test_series = monthly_series[split_point:]
    
    print("\n" + "="*70)
    print("TRAINING MODELS")
    print("="*70)
    
    results = {}
    models_obj = {}
    
    try:
        print("\n1️⃣  ARIMA")
        model = ARIMA(train_series, order=(1, 1, 1))
        fitted = model.fit()
        arima_pred = fitted.get_forecast(steps=len(test_series)).predicted_mean
        
        arima_mae = mean_absolute_error(test_series, arima_pred)
        arima_rmse = np.sqrt(mean_squared_error(test_series, arima_pred))
        
        results['ARIMA'] = {'mae': arima_mae, 'rmse': arima_rmse}
        models_obj['ARIMA'] = fitted
        print(f"  ✓ MAE: {arima_mae:.0f} | RMSE: {arima_rmse:.0f}")
    except Exception as e:
        print(f"  ✗ ARIMA failed: {e}")
    
    try:
        print("\n2️⃣  XGBOOST")
        data = train_series.values
        X, y = [], []
        lags = [1, 3, 6, 12]
        
        for i in range(len(data) - max(lags)):
            X.append([data[i + max(lags) - lag] for lag in lags])
            y.append(data[i + max(lags)])
        
        xgb_model = xgb.XGBRegressor(n_estimators=200, max_depth=5, learning_rate=0.05, random_state=42)
        xgb_model.fit(np.array(X), np.array(y), verbose=False)
        
        history = train_series.copy()
        xgb_pred = []
        for _ in range(len(test_series)):
            features = np.array([[history.values[-(lag)] for lag in lags]])
            pred = xgb_model.predict(features)[0]
            xgb_pred.append(pred)
            history = pd.concat([history, pd.Series([pred], index=[history.index[-1] + pd.DateOffset(months=1)])])
        
        xgb_mae = mean_absolute_error(test_series, xgb_pred)
        xgb_rmse = np.sqrt(mean_squared_error(test_series, xgb_pred))
        
        results['XGBoost'] = {'mae': xgb_mae, 'rmse': xgb_rmse}
        models_obj['XGBoost'] = xgb_model
        print(f"  ✓ MAE: {xgb_mae:.0f} | RMSE: {xgb_rmse:.0f}")
    except Exception as e:
        print(f"  ✗ XGBoost failed: {e}")
    
    print("\n" + "="*70)
    print("MODEL COMPARISON")
    print("="*70)
    
    comparison = []
    for name, data in results.items():
        comparison.append({'Model': name, 'MAE': round(data['mae'], 0), 'RMSE': round(data['rmse'], 0)})
    
    comparison_df = pd.DataFrame(comparison).sort_values('MAE')
    print("\n" + comparison_df.to_string(index=False))
    comparison_df.to_csv(Config.RESULTS_DIR / 'phase3_model_comparison.csv', index=False)
    
    best_model_name = comparison_df.iloc[0]['Model']
    best_model = models_obj[best_model_name]
    
    print("\n" + "="*70)
    print(f"FUTURE FORECAST (12 months) - {best_model_name}")
    print("="*70)
    
    if best_model_name == 'ARIMA':
        forecast = best_model.get_forecast(steps=Config.FORECAST_HORIZON).predicted_mean
        conf = best_model.get_forecast(steps=Config.FORECAST_HORIZON).conf_int()
        conf_lower = conf.iloc[:, 0].values
        conf_upper = conf.iloc[:, 1].values
    else:
        history = monthly_series.copy()
        forecast = []
        lags = [1, 3, 6, 12]
        for _ in range(Config.FORECAST_HORIZON):
            features = np.array([[history.values[-(lag)] for lag in lags]])
            pred = best_model.predict(features)[0]
            forecast.append(pred)
            history = pd.concat([history, pd.Series([pred], index=[history.index[-1] + pd.DateOffset(months=1)])])
        forecast = np.array(forecast)
        conf_lower = forecast * 0.9
        conf_upper = forecast * 1.1
    
    future_dates = pd.date_range(start=monthly_series.index[-1] + pd.DateOffset(months=1), periods=Config.FORECAST_HORIZON, freq='MS')
    
    forecast_df = pd.DataFrame({'date': future_dates, 'forecast': forecast, 'ci_lower': conf_lower, 'ci_upper': conf_upper})
    
    print("\n" + forecast_df.to_string(index=False))
    forecast_df.to_csv(Config.OUTPUT_DIR / 'phase3_forecast_12m.csv', index=False)
    
    print("\n" + "="*70)
    print("PHASE 3 COMPLETE ✓")
    print("="*70)
    print(f"\n✓ Using CLEAN data (standardized makes)")
    print(f"✓ Best model: {best_model_name}")
    print(f"✓ Files saved")

if __name__ == "__main__":
    main()
