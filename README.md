# TransportSense — Urban Transport Emission Analysis Engine

> A full-stack Haskell project that models, analyses, and visualises urban transport CO₂ emissions using higher-order functional abstractions — with both a CLI interface and an interactive web dashboard.

**Course:** SEM-4 · Principles of Functional Languages (PFL)  
**License:** MIT  
**Language:** Haskell (GHC ≥ 9.4) + HTML/CSS/JS (Dashboard)

---

## Table of Contents

- [Overview](#overview)
- [Features Implemented](#features-implemented)
- [Project Structure](#project-structure)
- [Dataset](#dataset)
- [How to Build & Run](#how-to-build--run)
  - [Prerequisites](#prerequisites)
  - [CLI Application](#cli-application)
  - [Web Dashboard](#web-dashboard)
- [CLI Usage](#cli-usage)
  - [Interactive Menu](#interactive-menu)
  - [Direct Commands](#direct-commands)
- [Web Dashboard Pages](#web-dashboard-pages)
- [Architecture Overview](#architecture-overview)
  - [Module Map](#module-map)
  - [Data Flow](#data-flow)
  - [Higher-Order Abstractions](#higher-order-abstractions)
- [Emission Formula](#emission-formula)
- [Policy Scenarios](#policy-scenarios)
- [Tests](#tests)
- [Technologies](#technologies)

---

## Overview

**TransportSense** analyses transport emission data across global cities to answer questions like:

- Which cities emit the most CO₂ per capita per day?
- How sensitive are emissions to shifts in modal share (e.g. +5% car → rail)?
- What happens if a city adopts an EV transition or active mobility policy?
- How have emission trends changed from 2015 to 2024?

The project is split into three layers:

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Core Library** | Pure Haskell (`src/`) | Emission models, sensitivity analysis, simulations, rankings, statistics |
| **CLI** | Haskell (`app/`, `cli/`) | Interactive menu + direct command-line interface |
| **Web Dashboard** | Scotty + HTML/JS/Chart.js (`scotty-web/`) | Visual analytics with charts, tables, and live filtering |

---

## Features Implemented

### Core Analysis Engine
- ✅ CSV dataset loading and parsing (13-column format)
- ✅ Per-capita daily emission calculation (CO₂, NOₓ, PM10, Energy)
- ✅ City-year aggregation across all transport modes
- ✅ Statistical analysis (mean, std-dev, min, max, median)
- ✅ Pearson correlation analysis (car share vs CO₂, rail share vs CO₂, etc.)
- ✅ Continent-level summaries

### Sensitivity Analysis
- ✅ Modal share sensitivity (±5 pct-pt perturbation per mode)
- ✅ Emission factor sensitivity (±10% relative perturbation)
- ✅ Elasticity computation (dimensionless ΔCO₂% / Δshare%)

### Policy Simulation
- ✅ 5 predefined policy scenarios (Rail Push, EV Transition, Active Mobility, BRT, Zero Car City)
- ✅ Scenario comparison per city-year
- ✅ Best-scenario-per-city ranking

### Rankings
- ✅ Rank by CO₂ (lowest first)
- ✅ Rank by low-carbon share (highest first)
- ✅ Rank by EV share (highest first)
- ✅ Rank by energy consumption (lowest first)

### Trend Analysis
- ✅ CO₂ trend slopes (linear regression) per city
- ✅ Year-over-year percentage change

### Higher-Order Abstractions
- ✅ `EmissionModel` newtype with `Semigroup` and `Monoid` instances
- ✅ `linearModel`, `weightedModel`, `sensitivityModel` — composable model constructors
- ✅ Higher-order `rankByMetric` accepting any scoring function
- ✅ Numerical partial differentiation via `numericalPartial`

### JSON Export
- ✅ Full analysis pipeline exported to a single `analysis.json`
- ✅ Hand-written JSON serialiser (zero external dependencies)
- ✅ Exports: city metrics, mode shares, emission breakdowns, trends, sensitivity, scenarios, rankings, global summary, continent summary, correlations, mode shifts

### CLI Interface
- ✅ Interactive menu with sub-menus (rankings, city deep-dive, scenarios)
- ✅ Direct command-line arguments for scripting
- ✅ Formatted table output with column alignment

### Web Dashboard (Scotty)
- ✅ Firebase Authentication (email/password + Google sign-in)
- ✅ Global Stats page (KPIs, CO₂ by continent, green score, trend charts)
- ✅ Sensitivity page (mode impact matrix, emission breakdown charts)
- ✅ Country Compare page (bar charts, detailed tables, region filtering)
- ✅ Modal Split page (car, rail, bus, motorcycle, walking, cycling, EV rankings)
- ✅ Time Animation page (animated year-by-year bar chart with play/pause)
- ✅ Emission Calculator (custom modal share input → CO₂ calculation)
- ✅ Import Dataset page (drag-and-drop JSON upload with mini-dashboard)
- ✅ AI Prediction page (links to Gemini, ChatGPT, Claude, Copilot, Perplexity, NotebookLM)
- ✅ Dark/Light theme toggle
- ✅ Responsive mobile layout with hamburger menu
- ✅ CSV & PDF export from calculator results

---

## Project Structure

```
transport-emissions/
├── app/
│   └── Main.hs                  # Entry point — routes CLI args or launches menu
├── cli/
│   ├── CLI.hs                   # CLICommand ADT + argument parser + runner
│   └── Menu.hs                  # Interactive menu system (main, rank, city, scenario)
├── src/
│   ├── Types.hs                 # All algebraic data types (TransportRecord, CityMetrics, etc.)
│   ├── Models.hs                # Higher-order EmissionModel with Semigroup/Monoid
│   ├── DatasetLoader.hs         # CSV parser (pure, no external libs)
│   ├── Preprocessing.hs         # Filtering, grouping, getCities, getYears
│   ├── EmissionCalculator.hs    # Core formula: pkm, dailyCO2PerCapita, etc.
│   ├── EmissionEngine.hs        # ADT-dispatch metric runner (CO2, NOx, PM10, Energy)
│   ├── EnergyEngine.hs          # Energy intensity and efficiency metrics
│   ├── CityAggregation.hs       # Aggregate records → CityMetrics
│   ├── Statistics.hs            # Stats, Pearson correlation, linear regression
│   ├── Sensitivity.hs           # Modal share and emission factor sensitivity
│   ├── PolicyModel.hs           # 5 predefined policy scenarios
│   ├── Simulation.hs            # Scenario simulation engine
│   ├── TrendAnalysis.hs         # CO₂ trend slopes and year-over-year change
│   ├── ModeAnalysis.hs          # Mode share matrix, shifts, emission breakdown
│   ├── Ranking.hs               # Rankings by CO₂, green share, EV, energy
│   ├── Analysis.hs              # Master orchestrator (fullCityReport, globalSummary)
│   ├── JsonExport.hs            # Hand-written JSON serialiser for all outputs
│   └── Utils.hs                 # Formatting helpers (fmtDouble, roundTo, splitOn)
├── data/
│   └── eu_transport.csv         # Dataset — 4000+ records, 50 cities, 2015–2024
├── test/
│   ├── DatasetTest.hs           # CSV parsing tests
│   ├── EmissionTest.hs          # Emission calculation tests
│   └── SimulationTest.hs        # Scenario simulation tests
├── scotty-web/
│   ├── app/
│   │   └── Web.hs               # Scotty web server (port 3000)
│   ├── static/
│   │   ├── index.html           # Login page (Firebase Auth)
│   │   ├── dashboard.html       # Main dashboard (8 pages, charts, tables)
│   │   └── analysis.json        # Pre-generated analysis data for the dashboard
│   ├── package.yaml             # Stack config for scotty-web
│   └── stack.yaml               # Stack resolver
├── docs/
│   ├── architecture.md          # Detailed architecture documentation
│   ├── dataset_description.md   # Dataset schema and field descriptions
│   └── formulas.md              # Mathematical formulas used
├── transport-emissions.cabal    # Cabal build configuration
├── LICENSE                      # MIT License
└── README.md                    # This file
```

---

## Dataset

The dataset (`data/eu_transport.csv`) contains **~4000 records** covering **50 cities** across all continents from **2015 to 2024**.

**CSV columns:**

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | `city` | String | City name (e.g. Mumbai, Berlin, Lagos) |
| 2 | `country` | String | Country name |
| 3 | `continent` | String | Continent (Asia, Europe, Africa, etc.) |
| 4 | `population` | Int | City population |
| 5 | `year` | Int | Data year (2015–2024) |
| 6 | `transport_mode` | String | One of: Car, Motorcycle, ElectricCar, Bus, Rail, Bicycle, Walk |
| 7 | `modal_share_pct` | Double | Percentage share of this mode (sums to ~100%) |
| 8 | `avg_trip_km` | Double | Average trip distance in km |
| 9 | `daily_trips` | Int | Average trips per person per day |
| 10 | `emission_factor_co2` | Double | kg CO₂ per passenger-km |
| 11 | `emission_factor_nox` | Double | kg NOₓ per passenger-km |
| 12 | `emission_factor_pm10` | Double | kg PM10 per passenger-km |
| 13 | `energy_intensity` | Double | MJ per passenger-km |

Each city-year has **8 rows** (one per transport mode: Car, Motorcycle, ElectricCar, ElectricBike, Bus, Rail, Bicycle, Walk).

---

## How to Build & Run

### Prerequisites

- **GHC** ≥ 9.4 (install via [GHCup](https://www.haskell.org/ghcup/))
- **Cabal** ≥ 3.6 (included with GHCup)
- **Stack** (for the web dashboard — install via GHCup or standalone)

### CLI Application

```bash
# Clone the repository
git clone https://github.com/Ganath-Avinash/Traffic_Emission_Haskell.git
cd Traffic_Emission_Haskell

# Build the project
cabal build

# Run in interactive mode (launches the menu)
cabal run transport-emissions

# Run with a specific command
cabal run transport-emissions -- cities
cabal run transport-emissions -- city Berlin 2020
cabal run transport-emissions -- rank co2

# Run tests
cabal test
```

### Web Dashboard

```bash
# Navigate to the scotty-web directory
cd scotty-web

# Build with Stack
stack build

# Run the web server (starts on http://localhost:3000)
stack run scotty-web-exe

# Open in your browser:
#   http://localhost:3000          → Login page
#   http://localhost:3000/dashboard.html  → Dashboard (after login)
```

> **Note:** The dashboard reads pre-generated `analysis.json` from the `scotty-web/static/` folder. To regenerate this file, run the JSON export from the CLI application first.

---

## CLI Usage

### Interactive Menu

Running `cabal run transport-emissions` with no arguments launches the interactive menu:

```
  ================================================================

     Urban Transport Emissions - Haskell Analysis Engine
     Sensitivity of emissions to urban mobility shifts

     Dataset  : 8 global cities - 2015 to 2020
     Metrics  : CO2  NOx  PM10  Energy
     Analysis : Sensitivity  Scenarios  Rankings

  ================================================================

  --------------------------------------------
                 MAIN MENU
  --------------------------------------------
   1. City Metrics Overview
   2. Global Statistics
   3. Continent Summary
   4. Correlation Report
   5. City Rankings          → sub-menu
   6. City Deep-Dive         → sub-menu (Report + Sensitivity)
   7. Scenario Simulation    → sub-menu
   8. Best Scenario Per City
   9. CO2 Trend Analysis
   0. Exit
  --------------------------------------------
```

### Direct Commands

For scripting or quick queries, pass arguments directly:

| Command | Description |
|---------|-------------|
| `cities` | City metrics table (sorted by CO₂) |
| `city <name> <year>` | Full city report for a specific year |
| `global` | Global dataset summary (mean CO₂, energy, low-carbon share) |
| `continent` | Continent-level averages |
| `correlations` | Pearson correlation report |
| `rank co2` | Cities ranked by CO₂ (lowest first) |
| `rank green` | Cities ranked by low-carbon share (highest first) |
| `rank ev` | Cities ranked by EV share (highest first) |
| `rank energy` | Cities ranked by energy consumption (lowest first) |
| `sensitivity <city> <year>` | Sensitivity analysis for a city-year |
| `scenarios <city> <year>` | Run all policy scenarios |
| `best` | Best policy scenario for each city |
| `trends` | CO₂ trend slopes for all cities |
| `help` | Print usage help |

**Override the default dataset:** append a `.csv` path as the last argument:

```bash
cabal run transport-emissions -- cities path/to/custom_data.csv
```

---

## Web Dashboard Pages

| # | Page | Description |
|---|------|-------------|
| 01 | **Global Stats** | KPI cards, CO₂ by continent chart, green score chart, trend line, country table |
| 02 | **Sensitivity** | Mode impact matrix, emission breakdown, modal share shift comparison |
| 03 | **Country Compare** | Side-by-side bar charts for any metric (CO₂, green %, fossil %, car/rail/cycling/EV share) |
| 04 | **Modal Split** | Rankings for each transport mode (car, rail, bus, motorcycle, walking, cycling, EV) |
| 05 | **Time Animation** | Animated year-by-year bar chart with play/pause, speed control, and region filter |
| 06 | **Calculator** | Custom modal share sliders → compute CO₂, energy, annual emissions with charts |
| 07 | **Import Dataset** | Drag-and-drop JSON upload — renders a mini-dashboard from your own data |
| 08 | **AI Prediction** | Links to external AI tools (Gemini, ChatGPT, Claude, Copilot, Perplexity, NotebookLM) for forecasting |

**Additional features:** Dark/Light theme toggle, Firebase auth (email + Google), responsive mobile layout, CSV/PDF export.

---

## Architecture Overview

### Module Map

```
                          ┌─────────┐
                          │ Types   │  ← All ADTs
                          └────┬────┘
                               │
                          ┌────┴────┐
                          │ Models  │  ← Higher-order EmissionModel (Semigroup, Monoid)
                          └────┬────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
     ┌──────┴──────┐    ┌─────┴─────┐    ┌───────┴───────┐
     │DatasetLoader│    │ Preproc.  │    │ EmissionCalc  │
     └─────────────┘    └─────┬─────┘    └───────┬───────┘
                              │                  │
         ┌────────────────────┼──────────────────┤
         │          │         │         │        │
    ┌────┴───┐ ┌────┴───┐ ┌──┴──┐ ┌────┴────┐ ┌─┴──────────┐
    │CityAgg │ │ModeAnal│ │Stats│ │EmEngine │ │EnergyEngine│
    └────────┘ └────────┘ └─────┘ └─────────┘ └────────────┘
         │          │         │
    ┌────┴───┐ ┌────┴───┐ ┌──┴──────┐ ┌─────────┐
    │Ranking │ │TrendAn │ │Sensitiv.│ │PolicyMod│
    └────────┘ └────────┘ └─────────┘ └────┬────┘
                                           │
                                     ┌─────┴─────┐
                                     │Simulation │
                                     └───────────┘
         All above ──→  Analysis  ──→  JsonExport
                           │
                     ┌─────┴─────┐
                     │  CLI/Menu │
                     └───────────┘
```

### Data Flow

```
CSV file
   │
   ▼
DatasetLoader.loadDataset        →  [TransportRecord]
   │
   ├──→ CityAggregation.aggregateAll    →  [CityMetrics]
   ├──→ Sensitivity.runAllSensitivities →  [SensitivityResult]
   ├──→ Simulation.simulateAllCities    →  [ScenarioResult]
   ├──→ Ranking.rankByCO2 / rankByGreen →  [RankEntry]
   ├──→ TrendAnalysis.allCityTrends     →  [(city, slope, v15, v20)]
   ├──→ Analysis.globalSummary          →  (Stats, Stats, Stats)
   └──→ Analysis.correlationReport      →  [(label, r)]
                         │
                         ▼
               JsonExport.exportAllJson   →  analysis.json
                         │
                         ▼
               Web Dashboard (Chart.js)
```

### Higher-Order Abstractions

| Abstraction | Module | Description |
|-------------|--------|-------------|
| `EmissionModel` (newtype) | Models | Wraps `[TransportRecord] → Double`; has `Semigroup` and `Monoid` |
| `linearModel` | Models | `sum . map ef` — sum emission over all modes |
| `weightedModel` | Models | Weight each mode's emission by a mode-specific factor |
| `sensitivityModel` | Models | Perturb + compare two models |
| `metricFn` | EmissionEngine | ADT-dispatched: returns `TransportRecord → Double` for any metric |
| `rankByMetric` | Ranking | Accepts any `[TransportRecord] → Double` scoring function |
| `elasticity` | Sensitivity | `(ΔOutput/Output) / (ΔInput/Input)` — dimensionless |

---

## Emission Formula

```
pkm(record)   = (modal_share / 100) × avg_trip_km × daily_trips
CO₂(record)   = pkm × emission_factor_CO₂           [kg/person/day]
Total CO₂     = Σ CO₂(record)  for all modes in a city-year
Annual CO₂    = Total CO₂ × population × 365 / 1000  [tonnes/year]
```

The same `emissionContribution` function is reused for NOₓ, PM10, and Energy by passing different emission factor selectors — this is the higher-order pattern at the core of the project.

---

## Policy Scenarios

| Scenario | Modal Share Shifts | Goal |
|----------|--------------------|------|
| **Rail Push** | Rail +10%, Car −10% | Shift trips from car to rail |
| **EV Transition** | ElectricCar +10%, Car −10% | Replace conventional cars with EVs |
| **Active Mobility** | Walk +5%, Bicycle +5%, Motorcycle −10% | Promote walking and cycling |
| **Bus Rapid Transit** | Bus +8%, Car −8% | Expand bus network |
| **Zero Car City** | Car −20%, Rail +10%, ElectricCar +10% | Halve car dependency |

After applying shifts, modal shares are **renormalised to 100%** to maintain physical consistency.

---

## Tests

The project includes three test modules:

```bash
cabal test
```

| Test Module | What It Tests |
|-------------|---------------|
| `DatasetTest.hs` | CSV parsing, record validation, malformed line handling |
| `EmissionTest.hs` | pkm calculation, CO₂/NOₓ/PM10 daily values, aggregation |
| `SimulationTest.hs` | Scenario application, share normalisation, CO₂ reduction |

---

## Technologies

| Component | Technology |
|-----------|-----------|
| Core Language | Haskell (GHC 9.4+) |
| Build System | Cabal (CLI) + Stack (Web server) |
| Web Framework | [Scotty](https://hackage.haskell.org/package/scotty) |
| Charts | [Chart.js](https://www.chartjs.org/) 4.4 |
| Authentication | [Firebase Auth](https://firebase.google.com/docs/auth) |
| Fonts | Inter, JetBrains Mono (Google Fonts) |
| Dependencies | `base`, `containers`, `directory` (CLI) · `scotty`, `text`, `bytestring`, `process` (Web) |

---

*Built for SEM-4 PFL — Principles of Functional Languages.*
