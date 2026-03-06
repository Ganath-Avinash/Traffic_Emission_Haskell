module JsonExport
  ( exportAllJson
  , toJson
  ) where

import Types
import CityAggregation (aggregateAll, cityYearPairs)
import ModeAnalysis (modeShareMatrix, modeShifts, modeEmissionBreakdown, lowCarbonShares)
import TrendAnalysis (allCityTrends, co2Trend, modalShareTrend)
import Sensitivity (runAllSensitivities)
import Simulation (simulateAllCities, bestScenarioPerCity)
import Ranking (rankByCO2, rankByLowCarbon, rankByEVShare, rankByEnergy)
import Analysis (globalSummary, continentSummary, correlationReport)
import Statistics (computeStats)
import Preprocessing (getCities, getYears, recordsForCityYear)
import Utils (roundTo)

import System.Directory (createDirectoryIfMissing)

exportAllJson :: [TransportRecord] -> FilePath -> IO ()
exportAllJson recs outDir = do
  createDirectoryIfMissing True outDir
  writeFile (outDir ++ "/city_metrics.json")      (cityMetricsJson recs)
  writeFile (outDir ++ "/mode_shares.json")        (modeSharesJson recs)
  writeFile (outDir ++ "/emission_breakdown.json") (emissionBreakdownJson recs)
  writeFile (outDir ++ "/trends.json")             (trendsJson recs)
  writeFile (outDir ++ "/sensitivity.json")        (sensitivityJson recs)
  writeFile (outDir ++ "/scenarios.json")          (scenariosJson recs)
  writeFile (outDir ++ "/rankings.json")           (rankingsJson recs)
  writeFile (outDir ++ "/global_summary.json")     (globalSummaryJson recs)
  writeFile (outDir ++ "/continent_summary.json")  (continentSummaryJson recs)
  writeFile (outDir ++ "/correlations.json")       (correlationsJson recs)
  writeFile (outDir ++ "/mode_shifts.json")        (modeShiftsJson recs)
  putStrLn "All JSON files written."

-- ─── Helpers ────────────────────────────────────────────────────────────────

class ToJson a where
  toJson :: a -> String

showD :: Double -> String
showD = show . roundTo 6

jStr :: String -> String
jStr s = "\"" ++ s ++ "\""

jField :: String -> String -> String
jField k v = jStr k ++ ": " ++ v

jObj :: [String] -> String
jObj fields = "{" ++ intercalate ", " fields ++ "}"

jArr :: [String] -> String
jArr xs = "[" ++ intercalate ", " xs ++ "]"

intercalate :: String -> [String] -> String
intercalate _ []     = ""
intercalate _ [x]    = x
intercalate sep (x:xs) = x ++ sep ++ intercalate sep xs

-- ─── City Metrics ───────────────────────────────────────────────────────────

cityMetricsJson :: [TransportRecord] -> String
cityMetricsJson recs =
  let metrics = aggregateAll recs
  in jArr (map cmToJson metrics)

cmToJson :: CityMetrics -> String
cmToJson m = jObj
  [ jField "city"            (jStr (cmCity m))
  , jField "country"         (jStr (cmCountry m))
  , jField "continent"       (jStr (cmContinent m))
  , jField "year"            (show (cmYear m))
  , jField "population"      (show (cmPopulation m))
  , jField "total_co2"       (showD (cmTotalCO2 m))
  , jField "total_nox"       (showD (cmTotalNOx m))
  , jField "total_pm10"      (showD (cmTotalPM10 m))
  , jField "total_energy"    (showD (cmTotalEnergy m))
  , jField "low_carbon_share" (showD (cmLowCarbonShare m))
  , jField "car_share"       (showD (cmCarShare m))
  , jField "rail_share"      (showD (cmRailShare m))
  ]

-- ─── Mode Shares ────────────────────────────────────────────────────────────

modeSharesJson :: [TransportRecord] -> String
modeSharesJson recs =
  let pairs = cityYearPairs recs
      entries = [ modeShareEntry c y recs | (c, y) <- pairs ]
  in jArr entries

modeShareEntry :: String -> Int -> [TransportRecord] -> String
modeShareEntry city year recs =
  let matrix = modeShareMatrix city year recs
      modePairs = [ jObj [ jField "mode" (jStr (modeLabel m))
                          , jField "share" (showD s) ]
                  | (m, s) <- matrix ]
  in jObj
       [ jField "city"  (jStr city)
       , jField "year"  (show year)
       , jField "modes" (jArr modePairs)
       ]

-- ─── Emission Breakdown ─────────────────────────────────────────────────────

emissionBreakdownJson :: [TransportRecord] -> String
emissionBreakdownJson recs =
  let pairs = cityYearPairs recs
      entries = [ breakdownEntry c y recs | (c, y) <- pairs ]
  in jArr entries

breakdownEntry :: String -> Int -> [TransportRecord] -> String
breakdownEntry city year recs =
  let bd = modeEmissionBreakdown city year recs
      items = [ jObj [ jField "mode"    (jStr (modeLabel m))
                      , jField "co2"    (showD co2)
                      , jField "pct"    (showD pct) ]
              | (m, co2, pct) <- bd ]
  in jObj
       [ jField "city"      (jStr city)
       , jField "year"      (show year)
       , jField "breakdown" (jArr items)
       ]

-- ─── Trends ─────────────────────────────────────────────────────────────────

trendsJson :: [TransportRecord] -> String
trendsJson recs =
  let cityTrends = allCityTrends recs
      entries = [ jObj [ jField "city"    (jStr c)
                        , jField "slope"   (showD slp)
                        , jField "co2_2015" (showD v15)
                        , jField "co2_2020" (showD v20)
                        , jField "pct_change" (showD (if v15 == 0 then 0 else (v20 - v15) / v15 * 100))
                        ]
              | (c, slp, v15, v20) <- cityTrends ]
  in jArr entries

-- ─── Sensitivity ────────────────────────────────────────────────────────────

sensitivityJson :: [TransportRecord] -> String
sensitivityJson recs =
  let cities = getCities recs
      years  = getYears recs
      results = [ runAllSensitivities (recordsForCityYear c y recs)
                | c <- cities, y <- years ]
      allResults = concat results
      entries = map srToJson allResults
  in jArr entries

srToJson :: SensitivityResult -> String
srToJson sr = jObj
  [ jField "city"        (jStr (srCity sr))
  , jField "year"        (show (srYear sr))
  , jField "mode"        (jStr (modeLabel (srMode sr)))
  , jField "parameter"   (jStr (srParameter sr))
  , jField "delta"       (showD (srDelta sr))
  , jField "base_co2"    (showD (srBaseCO2 sr))
  , jField "new_co2"     (showD (srNewCO2 sr))
  , jField "elasticity"  (showD (srElasticity sr))
  ]

-- ─── Scenarios ──────────────────────────────────────────────────────────────

scenariosJson :: [TransportRecord] -> String
scenariosJson recs =
  let results = simulateAllCities recs
  in jArr (map scToJson results)

scToJson :: ScenarioResult -> String
scToJson sc = jObj
  [ jField "scenario"      (jStr (psName (scScenario sc)))
  , jField "description"   (jStr (psDescription (scScenario sc)))
  , jField "city"          (jStr (scCity sc))
  , jField "year"          (show (scYear sc))
  , jField "base_co2"      (showD (scBaseCO2 sc))
  , jField "new_co2"       (showD (scNewCO2 sc))
  , jField "reduction_pct" (showD (scReductionPct sc))
  , jField "base_energy"   (showD (scBaseEnergy sc))
  , jField "new_energy"    (showD (scNewEnergy sc))
  ]

-- ─── Rankings ───────────────────────────────────────────────────────────────

rankingsJson :: [TransportRecord] -> String
rankingsJson recs =
  let co2Ranks   = take 20 (rankByCO2 recs)
      lcRanks    = take 20 (rankByLowCarbon recs)
      evRanks    = take 20 (rankByEVShare recs)
      enRanks    = take 20 (rankByEnergy recs)
      toEntry r  = jObj [ jField "rank"  (show (reRank r))
                         , jField "city"  (jStr (reCity r))
                         , jField "year"  (show (reYear r))
                         , jField "score" (showD (reScore r))
                         , jField "label" (jStr (reLabel r)) ]
  in jObj
       [ jField "by_co2"         (jArr (map toEntry co2Ranks))
       , jField "by_low_carbon"  (jArr (map toEntry lcRanks))
       , jField "by_ev_share"    (jArr (map toEntry evRanks))
       , jField "by_energy"      (jArr (map toEntry enRanks))
       ]

-- ─── Global Summary ─────────────────────────────────────────────────────────

globalSummaryJson :: [TransportRecord] -> String
globalSummaryJson recs =
  let (co2Stats, enStats, lcStats) = globalSummary recs
  in jObj
       [ jField "co2"    (statsJson co2Stats)
       , jField "energy" (statsJson enStats)
       , jField "low_carbon_share" (statsJson lcStats)
       ]

statsJson :: Stats -> String
statsJson s = jObj
  [ jField "mean"   (showD (statMean s))
  , jField "stddev" (showD (statStdDev s))
  , jField "min"    (showD (statMin s))
  , jField "max"    (showD (statMax s))
  , jField "median" (showD (statMedian s))
  ]

-- ─── Continent Summary ──────────────────────────────────────────────────────

continentSummaryJson :: [TransportRecord] -> String
continentSummaryJson recs =
  let summaries = continentSummary recs
      entries = [ jObj [ jField "continent"      (jStr cont)
                        , jField "avg_co2"         (showD co2)
                        , jField "avg_energy"      (showD en)
                        , jField "avg_low_carbon"  (showD lc) ]
              | (cont, co2, en, lc) <- summaries ]
  in jArr entries

-- ─── Correlations ───────────────────────────────────────────────────────────

correlationsJson :: [TransportRecord] -> String
correlationsJson recs =
  let corrs = correlationReport recs
      entries = [ jObj [ jField "pair" (jStr k), jField "r" (showD v) ]
              | (k, v) <- corrs ]
  in jArr entries

-- ─── Mode Shifts ────────────────────────────────────────────────────────────

modeShiftsJson :: [TransportRecord] -> String
modeShiftsJson recs =
  let cities = getCities recs
      shifts = concatMap (\c -> modeShifts c 2015 2020 recs) cities
      entries = [ jObj [ jField "city"       (jStr (msCity s))
                        , jField "mode"       (jStr (modeLabel (msMode s)))
                        , jField "share_2015" (showD (msShareFrom s))
                        , jField "share_2020" (showD (msShareTo s))
                        , jField "change"     (showD (msChange s)) ]
              | s <- shifts ]
  in jArr entries
