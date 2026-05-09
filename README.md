# Impact of Kenya's 2009 Fertilizer Subsidy Policy on Aggregate Agricultural Output
### An Interrupted Time Series (ITS) — ARIMAX Analysis | 1960–2022

<p align="center">
  <img src="https://img.shields.io/badge/Language-R-276DC3?style=for-the-badge&logo=r&logoColor=white"/>
  <img src="https://img.shields.io/badge/Method-ITS--ARIMAX-1F6B3A?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Data-FAOSTAT-orange?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Period-1960--2022-4A9B6F?style=for-the-badge"/>
  
</p>

---



##  Overview

Agriculture contributes approximately 22% of Kenya's GDP and employs over 40% of its population, yet smallholder yields remain persistently low due to the under-utilization of agricultural inputs. In 2009, the Kenyan government launched the **National Accelerated Agricultural Inputs Access Program (NAAIAP)** — a targeted voucher-based fertilizer subsidy programme aimed at resource-poor smallholder farmers.

This study evaluates the macro-level long-run impact of the NAAIAP on Kenya's **aggregate national agricultural output** using an **Interrupted Time Series (ITS) design with ARIMA errors (ARIMAX)**. Unlike existing evaluations that rely on short-panel or cross-sectional data, this approach enables detection of structural breaks in a 63-year longitudinal output trajectory — filling a critical methodological gap in the literature.

---

##  Research Objectives

Three ITS coefficients directly map to three research objectives:

| # | Coefficient | Objective |
|---|-------------|-----------|
| 1 | **β₁** | Determine the **pre-intervention baseline trend** (annual growth rate) of agricultural output before 2009 |
| 2 | **β₂** | Estimate the **immediate level change** — whether the policy caused a sudden jump in production in 2009 |
| 3 | **β₃** | Assess whether the **post-intervention growth rate** significantly accelerated or decelerated after 2009 |
| — | **β₄** | Land area elasticity — control variable to isolate the policy effect from land expansion |

---

##  Key Findings

| Variable | Coefficient | Significant? | Interpretation |
|----------|------------|:------------:|----------------|
| Pre-intervention trend (`time`) | +0.0275 |  Yes | Output grew **2.75% per year** before 2009 |
| Immediate level change (`intervention`) | −0.0396 |  No | **No significant immediate jump** in output at 2009 |
| Post-intervention slope (`post_time`) | −0.0219 |  Yes | Growth rate **decelerated by 2.19%/year** after 2009 |
| Land area elasticity (`land_area`) | +0.6082 |  Yes | **1% more land → 0.61% more output** |

> **Bottom Line:** The 2009 NAAIAP was **not associated with a sustained structural acceleration** in Kenya's aggregate agricultural output. Post-2009 annual growth dropped from 2.75% to approximately **0.56% per year**.

---


##  Dataset

| Property | Detail |
|----------|--------|
| **Source** | [FAOSTAT](https://www.fao.org/faostat/) via [Kaggle](https://www.kaggle.com/datasets/samuelkamau/kenyas-agricultural-production-1960-2022) |
| **Coverage** | Kenya, 1960–2022 (63 annual observations) |
| **Raw variables** | Total Production (tonnes), Area Harvested (hectares) |
| **Derived variables** | `ln_output`, `ln_land`, `time`, `intervention`, `post_time` |

### Variable Construction

```r
national_time_series <- national_data %>%
  mutate(
    ln_output    = log(total_production),               # Dependent variable
    ln_land      = log(area_harvested),                 # Control covariate
    time         = Year - 1959,                         # 1960=1, 1961=2...
    intervention = ifelse(Year >= 2009, 1, 0),          # Level change dummy
    post_time    = ifelse(Year >= 2009, Year - 2008, 0) # Slope change counter
  )
```

---

##  Model Specification

### ITS Regression Equation

$$\ln Y_t = \beta_0 + \beta_1 Time_t + \beta_2 Intervention_t + \beta_3 PostTime_t + \beta_4 \ln Z_t + \varepsilon_t$$

$$\varepsilon_t \sim ARIMA(0,0,3)$$

### Variable Definitions

| Symbol | Variable | Type | Role |
|--------|----------|------|------|
| ln Yₜ | Log total production (tonnes) | Dependent | Outcome |
| Timeₜ | Continuous counter (1960=1...) | Independent | Pre-intervention trend (β₁) |
| Interventionₜ | Binary dummy (0 before 2009; 1 from 2009) | Independent | Immediate level change (β₂) |
| PostTimeₜ | Years after 2009 (0, 1, 2, 3...) | Independent | Post-intervention slope (β₃) |
| ln Zₜ | Log area harvested (hectares) | Control | Land area elasticity (β₄) |

### Model Assumptions

1. **Linearity** — log-log specification linearizes the production relationship
2. **No anticipation effect** — farmers did not alter behaviour before the 2009 policy launch
3. **Known intervention date** — 2009 confirmed via Ministry of Agriculture documentation
4. **Stationarity** — achieved via first differencing; series confirmed I(1) by ADF test
5. **No concurrent confounders** — NAAIAP was the primary national input subsidy intervention introduced at this time
6. **ARIMA(0,0,3) error structure** — empirically selected by `auto.arima()` using AIC
7. **Exogeneity of land area** — within-period land use decisions assumed independent of output levels

---

##  Methodology

### Analytical Pipeline

```
Raw FAOSTAT Data
       │
       ▼
1. Data Cleaning & Preparation
   └── Aggregate production by year, log-transform, construct ITS variables
       │
       ▼
2. Exploratory Data Analysis
   └── Time-series line graph — visual inspection of trends and 2009 break
       │
       ▼
3. Stationarity Testing (ADF)
   ├── At levels:      p = 0.7623 → NON-STATIONARY
   └── After 1st diff: p = 0.01   → STATIONARY ✓  [Series is I(1)]
       │
       ▼
4. Baseline OLS ITS Model
   └── R² = 0.9875 — strong fit but residuals require investigation
       │
       ▼
5. Autocorrelation Diagnostics
   ├── Durbin-Watson = 0.539 (p = 6.875e-14) → SEVERE autocorrelation
   └── ACF: lags 1–4 dramatically outside 95% significance bounds
       │
       ▼
6. Final ARIMAX Model [auto.arima()]
   ├── ARIMA(0,0,3) error structure selected
   └── Residual ACF1 = −0.005 ≈ 0 → Autocorrelation RESOLVED ✓
       │
       ▼
7. Model Evaluation & Visualization
   └── MAPE = 0.19% | AIC = −195.83 | MASE = 0.596 | Log-lik = 106.91
```

### Methods Used

| Step | Method | R Package |
|------|--------|-----------|
| Visual inspection | Time-series line plots | `ggplot2` |
| Stationarity testing | Augmented Dickey-Fuller (ADF) test | `tseries` |
| Baseline model | OLS ITS regression | `stats` |
| Autocorrelation check | Durbin-Watson test + ACF plot | `lmtest` |
| Final model | ITS with ARIMA(0,0,3) errors | `forecast` |

---

## 📈 Results Summary

### Stationarity Tests

| Test | Series | Test Statistic | Lag Order | p-value | Decision |
|------|--------|:--------------:|:---------:|:-------:|----------|
| ADF | At levels | −1.5365 | 3 | 0.7623 |  Non-stationary |
| ADF | After 1st diff | −4.6004 | 3 | 0.01 |  Stationary — I(1) |

### Autocorrelation Diagnostics

| Diagnostic | Model | Statistic | Verdict |
|-----------|-------|-----------|---------|
| Durbin-Watson test | OLS | DW = 0.539, p = 6.875e-14 |  Severe autocorrelation |
| Residual ACF1 | ARIMAX | −0.005 |  Fully resolved |

### Final ARIMAX Model Output

```
Series: ln_output_ts
Regression with ARIMA(0,0,3) errors

Coefficients:
         ma1     ma2     ma3  intercept    time  intervention  post_time  land_area
      0.7441  0.7330  0.5829   -47.4235  0.0275       -0.0396    -0.0219     0.6082
s.e.  0.1287  0.1369  0.1244     2.6907  0.0017        0.0470     0.0086     0.0920

sigma^2 = 0.001965  |  log likelihood = 106.91
AIC = -195.83  |  AICc = -192.30  |  BIC = -176.83

Training set error measures:
  ME: -7.04e-05  |  RMSE: 0.04131  |  MAE: 0.03174
  MAPE: 0.19%    |  MASE: 0.596    |  ACF1: -0.005
```

### Post-Intervention Growth Rate Calculation

```
Total post-2009 growth rate = β₁ + β₃
                            = 0.0275 + (−0.0219)
                            = 0.0056
                            ≈ 0.56% per year  (down from 2.75%)
```

---





##  Authors

This project was completed as part of a research project at **Egerton University**, Department of Mathematics.

| Name |
|------|
| Ngondi Stalin Macharia |
| Nyambura Denis Kariuki |
| Angel Njeri Kimani |
| Kariuki Brian Gachina |
| Kogi Waweru Brandon |


---

##  Acknowledgements

- Data sourced from the [FAO FAOSTAT Database](https://www.fao.org/faostat/) via [Kaggle — Samuel Kamau](https://www.kaggle.com/datasets/samuelkamau/kenyas-agricultural-production-1960-2022)
- ITS methodology informed by Bernal et al. (2017) and Penfold & Zhang (2013)
- R packages: `forecast` (Hyndman & Khandakar, 2008), `tseries` (Trapletti & Hornik), `lmtest` (Zeileis & Hothorn, 2002)

---

##  Key References

- Bernal, J.L., Cummins, S. and Gasparrini, A. (2017). Interrupted time series regression for the evaluation of public health interventions. *International Journal of Epidemiology*, 46(1), 348–355.
- Jayne, T.S. and Rashid, S. (2013). Input subsidy programs in sub-Saharan Africa. *Agricultural Economics*, 44(6), 547–562.
- Mason, N.M., Jayne, T.S. and Mather, D. (2017). The effects of Kenya's 'smarter' input subsidy programme. *Journal of Agricultural Economics*, 68(1), 45–69.
- Nyoro, J.K., Kiiru, M.W. and Jayne, T.S. (1999). Evolution of Kenya's maize marketing systems in the post-liberalization era. Tegemeo Institute Working Paper 2A.
- Ricker-Gilbert, J., Jayne, T.S. and Chirwa, E. (2011). Subsidies and crowding out. *American Journal of Agricultural Economics*, 93(1), 26–42.
- Hyndman, R.J. and Khandakar, Y. (2008). Automatic time series forecasting: The forecast package for R. *Journal of Statistical Software*, 27(3), 1–22.

---


<p align="center">
  <i>Egerton University &nbsp;|&nbsp; Department of Mathematics &nbsp;|&nbsp; April 2026</i>
</p>
