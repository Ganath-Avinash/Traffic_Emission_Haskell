# Architecture

## Urban Transport Emissions — Haskell Analysis Engine

> Modelling the sensitivity of transport emissions to urban mobility shifts
> using higher-order abstractions in Haskell.

---

## 1. System Overview

The system is a pure-functional Haskell pipeline that:

1. **Loads** a CSV dataset of city-level transport records.
2. **Cleans & validates** records using `Either`-based error propagation.
3. **Computes** per-capita emission and energy metrics for each city-year.
4. **Runs sensitivity analysis** using higher-order numerical differentiation.
5. **Simulates scenarios** by applying higher-order modal-share transformations.
6. **Evaluates policies** using composable scenario runners.
7. **Exports** a structured JSON blob consumed by the web dashboard.

The CLI and interactive menu layer sit on top of the same pure analysis functions.

---

## 2. Module Dependency Graph

```
Types
  └── Models
        ├── DatasetLoader
        │     └── Preprocessing
        │           ├── EmissionCalculator
        │           │     └── EmissionEngine
        │           ├── EnergyEngine
        │           ├── Statistics
        │           ├── CityAggregation
        │           ├── ModeAnalysis
        │           ├── TrendAnalysis
        │           ├── Sensitivity
        │           ├── Simulation
        │           │     └── PolicyModel
        │           └── Ranking
        └── Analysis  ← orchestrates all of the above
              └── Utils

CLI  ← depends on Analysis
Menu ← depends on CLI
Main ← depends on CLI + Menu + DatasetLoader
```

All source modules under `src/` are pure (no `IO`). Only `DatasetLoader`, `Main`, and `Menu` perform IO.

---

## 3. Module Responsibilities

### `Types.hs`
Defines every algebraic data type in the system:

| Type | Purpose |
|---|---|
| `TransportRecord` | Raw row from CSV — one mode per city per year |
| `CityEmissions` | Aggregated city-year emissions across all modes |
| `SensitivityResult` | Result of shifting 1pp of modal share |
| `Scenario` | Named list of (fromMode, toMode, shift%) transformations |
| `ScenarioResult` | Pre/post CO₂ and energy for one city × scenario |
| `PolicyType` | ADT for policy instruments (5 variants) |
| `PolicyEffect` | CO₂ and energy reduction with cost estimate |
| `Stats` | Mean, std-dev, min, max, median |
| `TrendPoint` | (year, value) for time-series |
| `RankEntry` | (city, value, rank) for ranking tables |

### `Models.hs`
Higher-order abstractions that are the theoretical core of the project:

```haskell
-- Fold records with a custom combining function
foldRecords :: b -> (b -> TransportRecord -> b) -> [TransportRecord] -> b

-- Weighted aggregate: f(weight, value) over records
weightedAggregate :: (TransportRecord -> Double)
                  -> (TransportRecord -> Double)
                  -> [TransportRecord] -> Double

-- Numerical partial derivative of an arbitrary objective function
numericalPartial :: ([Double] -> Double) -> [Double] -> Int -> Double -> Double

-- Full gradient vector
gradient :: ([Double] -> Double) -> [Double] -> Double -> [Double]

-- Apply and normalise modal-share shifts (higher-order transformation)
applyShifts :: [(TransportMode, TransportMode, Double)]
            -> [TransportRecord] -> [TransportRecord]
```

These abstractions decouple the *what* (emission formula) from the *how* (which metric, which city, which shift).

### `DatasetLoader.hs`
Pure CSV parser using `Either ParseError TransportRecord`:

- `parseRecord :: String -> Either ParseError TransportRecord`
- Handles scientific notation (`6.55E-05`), leading/trailing whitespace, unknown transport modes.
- `loadDataset :: FilePath -> IO (Either [ParseError] [TransportRecord])`

### `Preprocessing.hs`
- **Validation**: `validateRecords` checks for negative shares, duplicate (city, year, mode) keys, shares not summing to ~100%.
- **Cleaning**: `cleanRecords` removes zero-trip-length rows; clamps emissions to ≥ 0.
- **Grouping**: `groupByCityYear`, `groupByCity` — foundational for all aggregation.
- **Filtering**: `filterByYear`, `filterByCity`, `filterByContinent`.

### `EmissionCalculator.hs`
Core emission formula:

```
pkm(r)              = (share/100) × avgTripKm × dailyTrips
CO₂(r)              = pkm(r) × emissionFactor_CO₂
totalCO₂(cityYear)  = Σ CO₂(r)  over all modes
annualCO₂(cityYear) = totalCO₂ × population × 365 / 1000   [tonnes]
```

### `EmissionEngine.hs`
ADT-dispatch emission runner. The `EmissionMetric` ADT enables higher-order metric selection:

```haskell
data EmissionMetric = CO2Metric | NOxMetric | PM10Metric | EnergyMetric

metricFn :: EmissionMetric -> (TransportRecord -> Double)
runMetric :: EmissionMetric -> [TransportRecord] -> Double
runAllMetrics :: [TransportRecord] -> [(EmissionMetric, Double)]
```

This lets callers pass a metric as a first-class value and drive computation without case-branching at the call site.

### `EnergyEngine.hs`
- `energyIntensityIndex` — total energy per pkm (proxy for system efficiency).
- `fossilFuelShare` — % energy from Car + Motorcycle + Bus.
- `renewableProxy` — % energy from EV + Rail + Walking + Cycling.
- `energyEfficiencyScore` — composite 0–100 score.
- `energySavingPotential` — MJ saved if all Car trips shifted to Rail.

### `Sensitivity.hs`
Sensitivity analysis via numerical differentiation:

1. For each ordered pair (fromMode, toMode) in a city-year:
   - Apply a 1 percentage-point shift using `applyShifts`.
   - Recompute total CO₂ (and NOₓ, PM10, energy).
   - Record `ΔCO₂% = (new − base) / base × 100`.
2. `elasticity(s) = ΔCO₂% / shiftPct` — the CO₂ elasticity of that modal shift.
3. `topSensitivities N` — ranked by `|ΔCO₂%|`.

The `numericalPartial` kernel in `Models.hs` is the theoretical basis; `sensitivityForCity` is its transport-domain instantiation.

### `Simulation.hs`
Six built-in scenarios using `applyShifts`:

| Scenario | Shifts |
|---|---|
| EV Transition | 10% Car → ElectricCar |
| Active Mobility | 5% Car → Cycling, 5% Car → Walking |
| Public Transit Boost | 15% Car → Rail, 5% Motorcycle → Bus |
| Car-Free City | 10% Car → Rail/Cycling/Walking each |
| Motorcycle to EV | 20% Motorcycle → ElectricCar |
| Optimal Green Mix | 10% Car → Rail, 5% Car → Cycling, 5% Moto → EV |

`runScenario` is a pure function; side effects are isolated in `Main`.

### `Statistics.hs`
- `computeStats` — mean, std-dev, min, max, median.
- `pearsonCorrelation` — Pearson r for two series.
- `linearRegression` — OLS regression `y = a + bx` (used for forecasting).
- `zScore`, `normalise` — vector normalisation helpers.
- `quartiles`, `outliers` — IQR-based outlier detection.

### `CityAggregation.hs`
- `aggregateCity` — collapses a city-year group into a `CityEmissions`.
- `cityComparison` — sorts cities by CO₂ descending.
- `continentSummary` — average CO₂ per continent.
- `populationWeightedAvg` — global weighted average CO₂.

### `ModeAnalysis.hs`
- `modeShareByContinent` — average share per mode per continent.
- `modeShareTrend` — `[(TransportMode, [TrendPoint])]` year-over-year.
- `dominantMode` — mode with highest share in a city-year.
- `modeEmissionProfile` — avg share, CO₂, energy per mode across all cities.
- `crossCityModeComparison` — all (city, year, share) for a given mode.

### `TrendAnalysis.hs`
- `emissionTrend` — `[TrendPoint]` for a city.
- `trendGrowthRate` — compound annual growth rate (CAGR).
- `yearOverYearChange` — list of `(fromYear, toYear, pct)`.
- `forecastLinear` — extrapolate using OLS regression to a future year.

### `Ranking.hs`
```haskell
greenScore :: [TransportRecord] -> Double
-- = 0.4 × greenMobilityIndex + 0.4 × normCO2 + 0.2 × evShare

sustainabilityIndex :: [TransportRecord] -> Double
-- = 0.5 × greenScore + 0.5 × energyEfficiencyScore
```

`rankByMetric` is a higher-order ranking function accepting any `([TransportRecord] -> Double)` as its scoring function.

### `PolicyModel.hs`
Five policy instruments, each implemented as a `Scenario`:

| Policy | Mechanism | €/tonne CO₂ |
|---|---|---|
| Car Restriction | 10% Car → Rail, 5% Car → Bus | 15 |
| Electric Subsidy | 15% Car → EV, 5% Moto → EV | 85 |
| Cycling Infrastructure | 10% Car → Cycling | 10 |
| Public Transit Expansion | 20% Car → Rail, 10% Moto → Rail | 30 |
| Congestion Charge | 12% Car → Rail, 5% → Cycling, 3% → Walking | 20 |

`evaluatePolicy pt rs` runs the corresponding scenario and wraps results in `PolicyEffect`.

### `Analysis.hs`
Master orchestrator:

```haskell
runFullAnalysis :: [TransportRecord] -> AnalysisOutput
exportJSON      :: AnalysisOutput    -> String
```

`AnalysisOutput` bundles every result type. `exportJSON` is a hand-written JSON serialiser (zero library dependencies).

### `Utils.hs`
Formatting primitives: `printf'`, `showPct`, `showKg`, `showMJ`, `tableFormat`, `barChart`, `clamp`, `roundTo`.

---

## 4. Data Flow

```
CSV file
   │
   ▼
DatasetLoader.loadDataset
   │  Either [ParseError] [TransportRecord]
   ▼
Preprocessing.cleanRecords
   │  [TransportRecord]
   ├──► Preprocessing.groupByCityYear ──► CityAggregation.aggregateAllCities
   │                                           │  [CityEmissions]
   ├──► Sensitivity.sensitivityMatrix          │
   │       │  [SensitivityResult]              ▼
   ├──► Simulation.scenarioComparison     continentSummary
   │       │  [ScenarioResult]            populationWeightedAvg
   ├──► PolicyModel.evaluatePolicy  ──► [PolicyEffect] per city
   ├──► Ranking.rankCitiesByGreenScore ──► [RankEntry]
   ├──► ModeAnalysis.modeShareTrend  ──► [(TransportMode,[TrendPoint])]
   └──► TrendAnalysis.cityEmissionTrajectory ──► [(String,[TrendPoint])]
              │
              ▼
       Analysis.AnalysisOutput
              │
              ▼
       Analysis.exportJSON ──► analysis.json ──► Web Dashboard
```

---

## 5. Higher-Order Abstractions Summary

| Abstraction | Location | Description |
|---|---|---|
| `foldRecords` | Models | Generalised fold over any record set |
| `weightedAggregate` | Models | Weighted mean of any record→Double function |
| `numericalPartial` | Models | ∂f/∂xᵢ for arbitrary objective f |
| `gradient` | Models | Full ∇f via repeated `numericalPartial` |
| `applyShifts` | Models | Higher-order modal share transformation |
| `metricFn` | EmissionEngine | Returns record→Double for any EmissionMetric |
| `runMetric` | EmissionEngine | `sum . map (metricFn m)` |
| `rankByMetric` | Ranking | Accepts any scoring function as argument |
| `filterBy` | Preprocessing | Generalised record predicate |
| `andFilter` | Preprocessing | Composes two predicates with `&&` |

---

## 6. Build & Run

### Requirements
- GHC ≥ 9.4 (or `ghcup install ghc recommended`)
- `cabal-install` ≥ 3.6

### Commands
```bash
# Build
cabal build

# Run CLI (produces JSON for website)
cabal run transport-emissions -- json > web/public/analysis.json

# Interactive menu
cabal run transport-emissions

# Specific commands
cabal run transport-emissions -- cities
cabal run transport-emissions -- scenarios Berlin
cabal run transport-emissions -- sensitivity Tokyo 20
cabal run transport-emissions -- policy Paris

# Run tests
cabal test
```

### Website
```bash
# Generate analysis data (Python fallback when GHC unavailable)
python3 generate_analysis.py data/eu_transport.csv web/public/analysis.json

# Open website
open web/public/index.html
# or serve with any static server:
cd web/public && python3 -m http.server 8080
```

---

## 7. Design Decisions

### Why Haskell?
- **Pure functions** make emission formulas referentially transparent — the same inputs always produce the same outputs, making testing trivial.
- **ADTs** (`TransportMode`, `EmissionMetric`, `PolicyType`) eliminate stringly-typed dispatch and give the compiler exhaustiveness checking.
- **Higher-order functions** allow the sensitivity kernel and scenario engine to be completely generic — the same `applyShifts` function powers every scenario and every policy.
- **`Either` error handling** in the parser means bad CSV rows are tracked and reported, not silently dropped.

### Why hand-written JSON?
The project targets zero external dependencies (only `base`). The JSON serialiser in `Analysis.hs` is ~80 lines and covers all needed types. This makes the library portable to any GHC environment without cabal dependency resolution.

### Why numerical differentiation instead of symbolic?
Symbolic differentiation of the emission formula would require a CAS or a differentiation library. Numerical differentiation via `numericalPartial` with `h = 1.0` (one percentage point) gives exact results for the piecewise-linear modal share model, since the emission function is linear in each modal share.
