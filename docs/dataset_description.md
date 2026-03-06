# Dataset Description

## Urban Transport Emissions Dataset

---

## 1. Overview

The dataset records transport modal splits, emission factors, and energy intensities for major global cities across two observation years (2015 and 2020). It is designed to support sensitivity analysis of transport-sector CO₂, NOₓ, and PM10 emissions to shifts in urban modal share.

| Property | Value |
|---|---|
| File | `data/eu_transport.csv` |
| Format | UTF-8 CSV with header row |
| Cities | 8 (Berlin, Lagos, Mumbai, New York, Paris, São Paulo, Sydney, Tokyo) |
| Years | 2015, 2020 |
| Modes per city-year | 7 (Car, Motorcycle, ElectricCar, Bus, Rail, Walking, Cycling) |
| Total rows | 112 (8 cities × 2 years × 7 modes) |
| Total columns | 13 |

---

## 2. Column Definitions

| Column | Type | Unit | Description |
|---|---|---|---|
| `city` | string | — | City name |
| `country` | string | — | Country name |
| `continent` | string | — | Continent: Asia, Europe, NorthAmerica, SouthAmerica, Africa, Oceania |
| `population` | integer | persons | City population at time of observation |
| `year` | integer | — | Observation year (2015 or 2020) |
| `transport_mode` | string | — | Mode: Car, Motorcycle, ElectricCar, Bus, Rail, Walking, Cycling |
| `modal_share_pct` | float | % | Share of all daily trips made by this mode in this city-year |
| `avg_trip_km` | float | km | Average one-way trip distance for this mode |
| `daily_trips` | float | trips/person/day | Average number of trips per person per day (all modes, not mode-specific) |
| `emission_factor_co2_kg_per_pkm` | float | kg CO₂ / pkm | Direct CO₂ emission factor (tailpipe + upstream where applicable) |
| `emission_factor_nox_kg_per_pkm` | float | kg NOₓ / pkm | NOₓ emission factor |
| `emission_factor_pm10_kg_per_pkm` | float | kg PM10 / pkm | Particulate matter (PM10) emission factor |
| `energy_intensity_MJ_per_pkm` | float | MJ / pkm | Final energy consumption per passenger-kilometre |

> **pkm** = passenger-kilometre = one passenger travelling one kilometre.

---

## 3. Cities

| City | Country | Continent | 2020 Population | Notes |
|---|---|---|---|---|
| Berlin | Germany | Europe | 3,645,000 | High rail share; active cycling policy |
| Lagos | Nigeria | Africa | 14,862,111 | High motorcycle share (okada); low rail |
| Mumbai | India | Asia | 20,700,000 | Largest city; high rail share (suburban rail) |
| New York | USA | NorthAmerica | 8,336,817 | High car dependency; strong rail in Manhattan |
| Paris | France | Europe | 2,161,000 | Metro city; low EV factor due to nuclear grid |
| São Paulo | Brazil | SouthAmerica | 12,325,232 | High car & bus; growing metro |
| Sydney | Australia | Oceania | 5,312,000 | High car dependency; growing EV adoption |
| Tokyo | Japan | Asia | 13,960,000 | World's highest rail share |

---

## 4. Transport Modes

| Mode | Zero-emission? | Motorised? | Notes |
|---|---|---|---|
| Car | No | Yes | ICE (internal combustion engine) average fleet |
| Motorcycle | No | Yes | Includes mopeds and scooters |
| ElectricCar | No* | Yes | Grid-mix CO₂ allocated; lower than ICE |
| Bus | No | Yes | Diesel fleet average |
| Rail | No* | Yes | Electric metro/suburban rail; CO₂ from grid |
| Walking | Yes | No | Zero direct & indirect emissions |
| Cycling | Yes | No | Zero direct & indirect emissions |

\* ElectricCar and Rail have near-zero direct emissions but non-zero upstream (grid) CO₂ included in the emission factor.

---

## 5. Emission Factors

Emission factors represent the total lifecycle emission per passenger-kilometre for each mode.

### CO₂ (kg/pkm)

| Mode | Typical range | Source basis |
|---|---|---|
| Car | 0.155 – 0.210 | IPCC AR6 Transport; EU fleet average |
| Motorcycle | 0.097 – 0.118 | EMEP/EEA Air Pollutant Emission Inventory |
| ElectricCar | 0.018 – 0.055 | IEA Electricity Mix (2015/2020 per country) |
| Bus | 0.071 – 0.094 | UITP; local fleet data |
| Rail | 0.022 – 0.045 | IEA; UIC |
| Walking | 0.0 | — |
| Cycling | 0.0 | — |

### NOₓ (kg/pkm)

NOₓ values are 10³–10⁴ times smaller than CO₂ values. Walking and Cycling have zero NOₓ.

### PM10 (kg/pkm)

PM10 values are expressed in scientific notation (e.g., `6.55E-05`). Brake and tyre wear are included for motorised modes.

### Energy Intensity (MJ/pkm)

| Mode | Typical range | Notes |
|---|---|---|
| Car | 1.89 – 2.50 | Petrol/diesel; ~25–35% thermal efficiency |
| Motorcycle | 1.31 – 1.60 | More efficient per vehicle, fewer passengers |
| ElectricCar | 0.18 – 0.56 | ~3–4× more efficient than ICE |
| Bus | 0.89 – 1.18 | High occupancy reduces per-pkm energy |
| Rail | 0.28 – 0.58 | Electric; very high occupancy |
| Walking | 0.0 | Not counted (human metabolic energy excluded) |
| Cycling | 0.0 | Not counted |

---

## 6. Modal Share

Modal shares are expressed as percentages of all daily trips for the city-year. Within each city-year, the seven mode shares sum to approximately 100%.

Minor deviations from 100% may arise due to rounding; `Preprocessing.validateRecords` flags city-years where the sum falls outside [99%, 101%].

### Sample (Mumbai 2020)

| Mode | Share % |
|---|---|
| Car | 15.2 |
| Motorcycle | 11.1 |
| ElectricCar | 5.6 |
| Bus | 27.0 |
| Rail | 24.5 |
| Walking | 11.6 |
| Cycling | 5.0 |
| **Total** | **100.0** |

---

## 7. Derived Variables (computed, not stored)

These are computed at runtime from the raw columns:

| Variable | Formula | Unit |
|---|---|---|
| `pkm` | `(share/100) × avgTripKm × dailyTrips` | pkm/person/day |
| `CO₂/person/day` | `pkm × emission_factor_co2` | kg/person/day |
| `NOₓ/person/day` | `pkm × emission_factor_nox` | kg/person/day |
| `PM10/person/day` | `pkm × emission_factor_pm10` | kg/person/day |
| `Energy/person/day` | `pkm × energy_intensity` | MJ/person/day |
| `Annual CO₂ (city)` | `CO₂_per_capita × population × 365 / 1000` | tonnes CO₂/year |
| `Green Mobility Index` | `Σ share where mode ∈ {Walking, Cycling, Rail}` | % |
| `Motorisation Rate` | `Σ share where mode is motorised` | % |
| `Fossil Fuel Share` | `Σ energy where mode ∈ {Car, Motorcycle, Bus} / Σ energy` | % |

---

## 8. Data Quality Notes

- **ElectricCar shares** in 2015 are very low (0.3–3.5%) across all cities, reflecting early-adoption stage; they increase markedly by 2020.
- **Rail share in Lagos** is very low (2.5% in 2015, 4.2% in 2020) reflecting minimal urban rail infrastructure.
- **Walking and Cycling** shares are lower in car-dependent cities (New York, Sydney) and higher in compact cities (Mumbai, Tokyo).
- **Emission factors** are held constant within a year for a given mode — they do not vary by city. This is a simplifying assumption; in reality, fleet age and driving conditions vary.
- **`daily_trips`** is set to 4 trips/person/day for all records (a typical NHTS/NTS average). Per-mode trip rates are not disaggregated in this dataset.

---

## 9. Data Sources and References

1. IPCC AR6 Working Group III, Chapter 10: Transport (2022).
2. IEA *Global EV Outlook* 2020, 2021.
3. EMEP/EEA Air Pollutant Emission Inventory Guidebook 2019.
4. UIC (International Union of Railways) *Railway Statistics* 2020.
5. UITP (International Association of Public Transport) *Mobility in Cities Database* 2021.
6. US NHTS (National Household Travel Survey) 2017.
7. European Commission *Handbook on External Costs of Transport* (2019).
8. City-level transport demand studies (Tokyo Metropolitan Government; Transport for NSW; Berlin Senat für Stadtentwicklung; Mumbai Metropolitan Region Development Authority).

---

## 10. Limitations

- The dataset covers only 8 cities; results should not be generalised to all cities worldwide.
- Emission factors represent fleet averages and do not capture within-city variation.
- The 4 trips/person/day assumption smooths over significant variation (1–8 trips/day in survey data).
- Modal shares represent trip counts, not trip distances — the two can diverge significantly for long-distance Rail trips.
- EV electricity emission factors use national grid averages; cities with renewable microgrids (e.g., parts of Paris) will have lower actual EV factors.
