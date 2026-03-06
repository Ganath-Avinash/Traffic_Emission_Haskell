# Formulas Reference

## Mathematical Foundations of the Transport Emissions Model

All formulas are implemented as pure Haskell functions. The Haskell source
reference is given alongside each formula.

---

## 1. Basic Emission Calculations

### 1.1 Passenger-Kilometres per Person per Day

For a given transport mode record **r**:

```
pkm(r) = (modal_share_pct(r) / 100) × avg_trip_km(r) × daily_trips(r)
```

**Unit**: pkm / person / day  
**Haskell**: `EmissionCalculator.pkm`

> *Interpretation*: the average number of kilometres travelled per person per day on mode **r**.

---

### 1.2 CO₂ Emission per Mode per Person per Day

```
CO₂(r) = pkm(r) × emission_factor_CO₂(r)
```

**Unit**: kg CO₂ / person / day  
**Haskell**: `EmissionCalculator.calcCO2PerCapitaDay`

Similarly for NOₓ, PM10, and energy:

```
NOₓ(r)     = pkm(r) × emission_factor_NOₓ(r)
PM10(r)    = pkm(r) × emission_factor_PM10(r)
Energy(r)  = pkm(r) × energy_intensity(r)
```

---

### 1.3 Total City-Level Emissions per Person per Day

Let **M** = set of all transport mode records for a city-year:

```
Total_CO₂   = Σ_{r ∈ M}  CO₂(r)
Total_NOₓ   = Σ_{r ∈ M}  NOₓ(r)
Total_PM10  = Σ_{r ∈ M}  PM10(r)
Total_E     = Σ_{r ∈ M}  Energy(r)
```

**Unit**: kg (or MJ) / person / day  
**Haskell**: `EmissionCalculator.calcCityTotalCO2Daily`, `Models.totalCO2`

---

### 1.4 Annual City CO₂ Emissions

```
AnnualCO₂ = Total_CO₂ × population × 365 / 1000
```

**Unit**: tonnes CO₂ / year  
**Haskell**: `EmissionCalculator.calcAnnualCO2Tonnes`

---

## 2. Energy Metrics

### 2.1 Energy Intensity Index

Weighted-average energy per pkm across all modes:

```
EnergyIntensityIndex = Total_E / Σ_{r ∈ M} pkm(r)
```

**Unit**: MJ / pkm  
**Haskell**: `EnergyEngine.energyIntensityIndex`

Lower values indicate a more energy-efficient transport system.

---

### 2.2 Fossil Fuel Share

Let **F** ⊂ M be the subset of fossil modes (Car, Motorcycle, Bus):

```
FossilFuelShare = (Σ_{r ∈ F} Energy(r)) / Total_E × 100
```

**Unit**: %  
**Haskell**: `EnergyEngine.fossilFuelShare`

---

### 2.3 Renewable Proxy Share

Let **R** ⊂ M be the subset of low/zero-carbon modes (ElectricCar, Rail, Walking, Cycling):

```
RenewableProxy = (Σ_{r ∈ R} Energy(r)) / Total_E × 100
```

**Unit**: %  
**Haskell**: `EnergyEngine.renewableProxy`

> *Note*: ElectricCar and Rail energy is included with their upstream (grid) factors. True renewability depends on the electricity mix.

---

### 2.4 Energy Saving Potential

Hypothetical energy saving if all car trips shifted to rail:

```
EnergySavingPotential = pkm_car × (EI_car − EI_rail)
```

Where:
- `pkm_car = (share_car/100) × avgTripKm_car × dailyTrips`
- `EI_car, EI_rail` = energy intensities of car and rail respectively

**Unit**: MJ / person / day  
**Haskell**: `EnergyEngine.energySavingPotential`

---

## 3. Sensitivity Analysis

### 3.1 Numerical Partial Derivative

Given an objective function **f : ℝⁿ → ℝ** (e.g., total CO₂ as a function of modal shares):

```
∂f/∂xᵢ ≈ (f(x₁, …, xᵢ + h, …, xₙ) − f(x₁, …, xᵢ, …, xₙ)) / h
```

**Haskell**: `Models.numericalPartial`

For the transport model, **h = 1.0** (one percentage point), and **f** is `totalCO₂`. This gives the exact finite-difference derivative because the emission formula is linear in modal shares:

```
Total_CO₂(shares) = Σᵢ (sᵢ/100) × avgTripKmᵢ × dailyTripsᵢ × EF_CO₂ᵢ
```

This is linear in each sᵢ, so the finite difference is exact.

---

### 3.2 Modal Share Shift (Sensitivity Kernel)

For a shift of **δ** percentage points from mode **i** to mode **j**:

```
shift(sᵢ) = sᵢ − δ
shift(sⱼ) = sⱼ + δ
shift(sₖ) = sₖ    for k ≠ i, j
```

Then re-normalise so that Σₖ shift(sₖ) = 100:

```
s'ₖ = shift(sₖ) × 100 / Σₘ shift(sₘ)
```

**Haskell**: `Models.applyShifts`, `Models.normaliseShares`

---

### 3.3 Sensitivity Result

```
ΔCO₂% = (Total_CO₂(shifted) − Total_CO₂(baseline)) / Total_CO₂(baseline) × 100
```

Similarly for ΔNOₓ%, ΔPM10%, ΔEnergy%.

**Haskell**: `Sensitivity.computeSens`

---

### 3.4 Elasticity

The CO₂ elasticity of a modal shift from mode **i** to mode **j**:

```
Elasticity(i→j) = ΔCO₂% / δ
```

Where **δ = 1** percentage point.

**Haskell**: `Sensitivity.elasticity`

> *Interpretation*: a shift of 1pp from Car to Rail with elasticity −2.1 means that for every 1pp shifted, total CO₂ falls by 2.1%.

---

## 4. Scenario Simulation

### 4.1 Scenario Application

A scenario is a list of triples: `[(fromMode, toMode, shift%)]`.

The scenario is applied by:
1. Adding `shift%` to `toMode` and subtracting it from `fromMode` for each triple.
2. Renormalising all shares to sum to 100.
3. Recomputing all emission metrics on the shifted records.

**Haskell**: `Simulation.runScenario`, `Models.applyShifts`

---

### 4.2 Scenario CO₂ Change

```
ΔCO₂_scenario = (Total_CO₂_new − Total_CO₂_baseline) / Total_CO₂_baseline × 100
```

**Haskell**: `Simulation.runScenario` → `scResChangePct`

---

### 4.3 Annual CO₂ Saving

```
AnnualSaving = (Total_CO₂_baseline − Total_CO₂_new) × population × 365 / 1000
```

**Unit**: tonnes CO₂ / year  

---

## 5. Composite Scores

### 5.1 Green Mobility Index (GMI)

```
GMI = Σ_{r: mode ∈ {Walking, Cycling, Rail}} modal_share_pct(r)
```

**Unit**: %  
**Haskell**: `Models.greenMobilityIndex`

---

### 5.2 Green Score

```
GreenScore = (0.4 × GMI/100 + 0.4 × normCO₂ + 0.2 × EVshare/100) × 100
```

Where:

```
normCO₂ = clamp(0, 1, (1.5 − Total_CO₂) / (1.5 − 0.1))
EVshare = modal_share_pct(ElectricCar)    [or 0 if absent]
```

**Unit**: 0–100 composite score (higher = greener)  
**Haskell**: `Ranking.greenScore`

The normalisation assumes CO₂ ranges from 0.1 kg/p/d (excellent) to 1.5 kg/p/d (poor), and clamps to [0, 1].

---

### 5.3 Energy Efficiency Score

```
normIdx = clamp(0, 1, (2.5 − EnergyIntensityIndex) / (2.5 − 0.3))
EnergyEfficiencyScore = (normIdx × 0.6 + renewProxy/100 × 0.4) × 100
```

**Unit**: 0–100  
**Haskell**: `EnergyEngine.energyEfficiencyScore`

Assumes energy intensity range: 0.3 MJ/pkm (very efficient) to 2.5 MJ/pkm (inefficient).

---

### 5.4 Sustainability Index

```
SustainabilityIndex = 0.5 × GreenScore + 0.5 × EnergyEfficiencyScore
```

**Haskell**: `Ranking.sustainabilityIndex`

---

## 6. Statistical Methods

### 6.1 Arithmetic Mean

```
μ = (1/n) Σᵢ xᵢ
```

### 6.2 Population Standard Deviation

```
σ = sqrt((1/n) Σᵢ (xᵢ − μ)²)
```

**Haskell**: `Statistics.computeStats`

---

### 6.3 Pearson Correlation Coefficient

```
r = Σᵢ (xᵢ − μₓ)(yᵢ − μᵧ) / (√Σᵢ(xᵢ−μₓ)² × √Σᵢ(yᵢ−μᵧ)²)
```

**Haskell**: `Statistics.pearsonCorrelation`

---

### 6.4 Ordinary Least Squares (OLS) Linear Regression

For points `{(xᵢ, yᵢ)}`, fit `y = a + bx`:

```
b = Σᵢ (xᵢ − μₓ)(yᵢ − μᵧ) / Σᵢ (xᵢ − μₓ)²
a = μᵧ − b × μₓ
```

**Haskell**: `Statistics.linearRegression`

Used in `TrendAnalysis.forecastLinear` to project emission trends to future years.

---

### 6.5 Compound Annual Growth Rate (CAGR)

Given a series from year **t₀** to year **t₁** with values **v₀** and **v₁**:

```
CAGR = ((v₁ / v₀)^(1 / (t₁ − t₀)) − 1) × 100
```

**Unit**: % per year  
**Haskell**: `TrendAnalysis.trendGrowthRate`

---

### 6.6 IQR Outlier Detection

```
IQR = Q3 − Q1
Lower fence = Q1 − 1.5 × IQR
Upper fence = Q3 + 1.5 × IQR
Outlier iff x < Lower fence  OR  x > Upper fence
```

**Haskell**: `Statistics.outliers`

---

## 7. Population-Weighted Average

For a set of cities with populations **pₖ** and per-capita CO₂ values **cₖ**:

```
WeightedAvgCO₂ = Σₖ (cₖ × pₖ) / Σₖ pₖ
```

**Haskell**: `CityAggregation.populationWeightedAvg`

---

## 8. Policy Cost Effectiveness

Each policy instrument has an estimated cost per tonne of CO₂ avoided (**€/tCO₂**), sourced from literature:

```
CostEffectiveness = policyCostPerTonne / max(CO₂reduction, ε)
```

Where **ε** is a small positive constant to avoid division by zero.

**Haskell**: `PolicyModel.costEffectiveness`

---

## 9. Weighted Emission Intensity

Average CO₂ emission factor weighted by modal share (motorised modes only):

```
AvgEI_CO₂ = Σ_{r ∈ Motorised} (share(r) × EF_CO₂(r)) / Σ_{r ∈ Motorised} share(r)
```

**Haskell**: `Models.avgEmissionIntensityCO2`

---

## 10. Summary of All Haskell Identifiers and Their Formulas

| Identifier | Module | Formula (informal) |
|---|---|---|
| `pkm` | EmissionCalculator | `(share/100) × tripKm × dailyTrips` |
| `calcCO2PerCapitaDay` | EmissionCalculator | `pkm × EF_CO₂` |
| `calcNOxPerCapitaDay` | EmissionCalculator | `pkm × EF_NOₓ` |
| `calcPM10PerCapitaDay` | EmissionCalculator | `pkm × EF_PM10` |
| `calcEnergyPerCapitaDay` | EmissionCalculator | `pkm × EI` |
| `calcCityTotalCO2Daily` | EmissionCalculator | `Σ calcCO2PerCapitaDay` |
| `calcAnnualCO2Tonnes` | EmissionCalculator | `total × pop × 365 / 1000` |
| `totalCO2` | Models | `sum . map calcCO2PerCapitaDay` |
| `totalEnergy` | Models | `sum . map calcEnergyPerCapitaDay` |
| `greenMobilityIndex` | Models | `Σ share where mode ∈ {Walk,Cycle,Rail}` |
| `motorisationRate` | Models | `Σ share where motorised` |
| `avgEmissionIntensityCO2` | Models | `Σ(share×EF) / Σshare` over motorised |
| `numericalPartial` | Models | `(f(x+h) − f(x)) / h` |
| `gradient` | Models | `map (numericalPartial f xs) [0..n-1]` |
| `applyShifts` | Models | shift + normalise shares |
| `energyIntensityIndex` | EnergyEngine | `Σenergy / Σpkm` |
| `fossilFuelShare` | EnergyEngine | `Σenergy_fossil / Σenergy × 100` |
| `renewableProxy` | EnergyEngine | `Σenergy_green / Σenergy × 100` |
| `energyEfficiencyScore` | EnergyEngine | `(0.6×normIdx + 0.4×renew) × 100` |
| `energySavingPotential` | EnergyEngine | `pkm_car × (EI_car − EI_rail)` |
| `greenScore` | Ranking | `(0.4×GMI + 0.4×normCO₂ + 0.2×EV) × 100` |
| `sustainabilityIndex` | Ranking | `0.5×greenScore + 0.5×eeScore` |
| `computeStats` | Statistics | mean, σ, min, max, median |
| `pearsonCorrelation` | Statistics | Pearson r |
| `linearRegression` | Statistics | OLS: a, b |
| `trendGrowthRate` | TrendAnalysis | CAGR |
| `forecastLinear` | TrendAnalysis | `a + b × year` |
| `yearOverYearChange` | TrendAnalysis | `(v₁−v₀)/v₀ × 100` per pair |
| `populationWeightedAvg` | CityAggregation | `Σ(c×pop) / Σpop` |
| `sensitivityForCity` | Sensitivity | `ΔCO₂%` per (from,to) pair |
| `elasticity` | Sensitivity | `ΔCO₂% / shift%` |
| `runScenario` | Simulation | `applyShifts` then `totalCO₂` |
| `evaluatePolicy` | PolicyModel | `runScenario (policyScenario pt)` |
