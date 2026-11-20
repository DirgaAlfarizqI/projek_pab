import os
import math
from typing import Optional
import pandas as pd
import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import uvicorn

app = FastAPI(
    title="TaniJagung ML Prediction API",
    description="API Prediksi Hasil Panen Jagung (Linear Regression & Random Forest Regression) untuk Aplikasi Flutter TaniJagung",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATASET_PATH = os.path.join(os.path.dirname(__file__), "corn_yield_dataset.csv")

VARIETY_ENCODING = {
    "BISI 18": 1.0,
    "NK 212": 2.0,
    "PIONEER P27": 3.0,
    "PERTIWI 3": 0.5,
}

class ModelRegistry:
    is_trained: bool = False
    dataset_rows: int = 0
    lr_model: Optional[LinearRegression] = None
    rf_model: Optional[RandomForestRegressor] = None
    lr_metrics: dict = {}
    rf_metrics: dict = {}

registry = ModelRegistry()

def encode_variety(variety_name: str) -> float:
    upper = variety_name.strip().upper()
    for key, val in VARIETY_ENCODING.items():
        if key in upper or upper in key:
            return val
    return 1.0

def train_and_evaluate_models():
    if not os.path.exists(DATASET_PATH):
        registry.is_trained = False
        return

    df = pd.read_csv(DATASET_PATH)
    if df.empty or len(df) < 10:
        registry.is_trained = False
        return

    registry.dataset_rows = len(df)
    df["variety_code"] = df["corn_variety"].apply(encode_variety)
    # Variabel fitur per hektare untuk stabilitas skala lahan
    df["seed_per_ha"] = df["seed_kg"] / df["area_ha"]
    df["fertilizer_per_ha"] = df["fertilizer_kg"] / df["area_ha"]
    df["yield_tons_per_ha"] = df["yield_tons"] / df["area_ha"]

    feature_cols = [
        "area_ha",
        "variety_code",
        "seed_per_ha",
        "fertilizer_per_ha",
        "historical_avg_tons_per_ha",
    ]
    X = df[feature_cols].values
    y = df["yield_tons_per_ha"].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.25, random_state=42
    )

    # 1. Linear Regression
    lr = LinearRegression()
    lr.fit(X_train, y_train)
    lr_pred = lr.predict(X_test)
    registry.lr_model = lr
    registry.lr_metrics = {
        "mae": round(float(mean_absolute_error(y_test, lr_pred)), 4),
        "rmse": round(float(math.sqrt(mean_squared_error(y_test, lr_pred))), 4),
        "r2": round(float(r2_score(y_test, lr_pred)), 4),
    }

    # 2. Random Forest Regression
    rf = RandomForestRegressor(n_estimators=120, random_state=42)
    rf.fit(X_train, y_train)
    rf_pred = rf.predict(X_test)
    registry.rf_model = rf
    registry.rf_metrics = {
        "mae": round(float(mean_absolute_error(y_test, rf_pred)), 4),
        "rmse": round(float(math.sqrt(mean_squared_error(y_test, rf_pred))), 4),
        "r2": round(float(r2_score(y_test, rf_pred)), 4),
    }

    registry.is_trained = True

train_and_evaluate_models()

class PredictionRequest(BaseModel):
    area_ha: float = Field(..., gt=0, description="Luas lahan dalam hektare")
    corn_variety: str = Field(..., description="Varietas jagung")
    seed_kg: float = Field(..., ge=0, description="Total benih digunakan (kg)")
    fertilizer_kg: float = Field(..., ge=0, description="Total pupuk digunakan (kg)")
    historical_avg_tons_per_ha: Optional[float] = Field(
        None, description="Rata-rata historis hasil panen (ton/ha)"
    )
    model_type: str = Field(
        "random_forest", description="random_forest atau linear_regression"
    )

@app.get("/health")
def health_check():
    return {
        "status": "ok",
        "model_trained": registry.is_trained,
        "dataset_rows": registry.dataset_rows,
        "models_available": [
            "Random Forest Regression",
            "Linear Regression",
        ],
        "evaluation_metrics": {
            "random_forest": registry.rf_metrics,
            "linear_regression": registry.lr_metrics,
        },
        "disclaimer": "Hasil merupakan estimasi statistik berdasarkan dataset historis, bukan jaminan hasil panen.",
    }

@app.post("/predict")
def predict_yield(req: PredictionRequest):
    if not registry.is_trained or registry.rf_model is None or registry.lr_model is None:
        raise HTTPException(
            status_code=503,
            detail="Dataset belum tersedia atau model belum dilatih. Sistem tidak menampilkan prediksi palsu.",
        )

    v_code = encode_variety(req.corn_variety)
    seed_per_ha = req.seed_kg / req.area_ha
    fert_per_ha = req.fertilizer_kg / req.area_ha
    hist_avg = (
        req.historical_avg_tons_per_ha
        if req.historical_avg_tons_per_ha is not None and req.historical_avg_tons_per_ha > 0
        else 7.0
    )

    X_input = np.array([[req.area_ha, v_code, seed_per_ha, fert_per_ha, hist_avg]])

    rf_tons_per_ha = max(0.5, float(registry.rf_model.predict(X_input)[0]))
    lr_tons_per_ha = max(0.5, float(registry.lr_model.predict(X_input)[0]))

    rf_total_tons = round(rf_tons_per_ha * req.area_ha, 3)
    lr_total_tons = round(lr_tons_per_ha * req.area_ha, 3)

    if req.model_type.lower() == "linear_regression":
        chosen_tons_per_ha = lr_tons_per_ha
        chosen_total_tons = lr_total_tons
        chosen_name = "Linear Regression"
        chosen_metrics = registry.lr_metrics
    else:
        chosen_tons_per_ha = rf_tons_per_ha
        chosen_total_tons = rf_total_tons
        chosen_name = "Random Forest Regression"
        chosen_metrics = registry.rf_metrics

    chosen_total_kg = round(chosen_total_tons * 1000.0, 2)
    chosen_kg_per_ha = round(chosen_tons_per_ha * 1000.0, 2)

    return {
        "model_used": chosen_name,
        "predicted_yield_tons": chosen_total_tons,
        "predicted_yield_kg": chosen_total_kg,
        "predicted_yield_kg_per_ha": chosen_kg_per_ha,
        "metrics": chosen_metrics,
        "comparison": {
            "random_forest": {
                "predicted_tons": rf_total_tons,
                "predicted_kg_per_ha": round(rf_tons_per_ha * 1000.0, 2),
                **registry.rf_metrics,
            },
            "linear_regression": {
                "predicted_tons": lr_total_tons,
                "predicted_kg_per_ha": round(lr_tons_per_ha * 1000.0, 2),
                **registry.lr_metrics,
            },
        },
        "disclaimer": "Hasil merupakan estimasi model Machine Learning, bukan jaminan hasil panen.",
    }

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)

