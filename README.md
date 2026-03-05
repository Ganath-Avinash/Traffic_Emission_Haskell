
# Transport Emissions Analysis System

A Haskell-based system for analyzing and modeling transport emissions across cities.  
The project begins as a **CLI tool**, evolves into a **web application**, and finally integrates **CLI + Web for a complete analytics platform**.

---

## Project Goals

- Model transport emissions using real datasets
- Analyze emissions across cities
- Provide simulation tools for emission reduction scenarios
- Offer both CLI and Web interfaces for analysis

---

## Project Phases

### Phase 1 – CLI System
- Emission calculator
- Menu-based CLI interface
- Dataset loading (CSV)
- City comparison
- Emission rankings

### Phase 2 – Data Analytics
- Statistical insights
- Vehicle type modeling
- Scenario simulation (EV adoption etc.)

### Phase 3 – Web Application
- Web server (Scotty framework)
- REST endpoints
- Interactive dashboard

### Phase 4 – Integrated System
- CLI + Web sharing core modules

### Phase 5 – Advanced Features
- Emission prediction
- Policy simulation
- Sustainability index

---

## Project Structure

```
transport-emissions/
├── app/
│   └── Main.hs
├── src/
│   ├── Types.hs
│   ├── EmissionCalculator.hs
│   ├── DataLoader.hs
│   ├── Analysis.hs
│   └── Utils.hs
├── web/
│   ├── Server.hs
│   ├── Routes.hs
│   └── Views.hs
├── data/
│   └── cities.csv
├── test/
│   └── TestEmission.hs
├── docs/
│   ├── architecture.md
│   └── report.md
├── transport-emissions.cabal
└── README.md
```

---

## Example CLI Interface

```
Transport Emissions System

1 Calculate emission
2 Compare cities
3 Load dataset
4 Show rankings
5 Exit
```

---

## Example Dataset

```
City,Population,Vehicles,Emission
Paris,2100000,1200000,2.3
Berlin,3600000,1800000,2.1
Madrid,3200000,1600000,2.2
```

---

## Team Roles

### Core Haskell Developer
- Emission algorithms
- Data models
- Analysis functions

### CLI & Data Engineer
- CLI interface
- Dataset processing
- File handling

### Web Developer
- Web server
- API endpoints
- Visualization dashboard

---

## Unique Features

- Transport emission modeling engine
- Multi-city comparison
- Scenario simulation (EV adoption etc.)
- Sustainability index for cities
- Interactive web dashboard

---

## Technologies

- Haskell
- Cabal
- Scotty (Web Framework)
- CSV datasets
- Chart.js / D3.js for visualization

---

## How to Run

Install dependencies:

```
cabal build
```

Run CLI:

```
cabal run
```

---

## Future Improvements

- Real EU transport datasets
- Machine learning emission prediction
- Geographic emission maps
