module SimulationTest (runTests) where

import Types
import EmissionEngine    (cityTotalCO2, cityTotalEnergy)
import Sensitivity
  ( runAllSensitivities, modalShareSensitivity, efSensitivity, elasticity )
import Simulation
  ( simulateCityScenarios, simulateAllCities, bestScenarioPerCity )
import PolicyModel
  ( predefinedScenarios, applyScenario, runScenarioForCity )
import TrendAnalysis
  ( co2Trend, modalShareTrend, trendSlope, allCityTrends )
import CityAggregation
  ( aggregateAll )
import ModeAnalysis
  ( dominantMode, modeShareMatrix, modeEmissionBreakdown )
import Preprocessing
  ( recordsForCityYear, getCities )
import Statistics
  ( linearRegression )

-- ─────────────────────────────────────────────────────────────────────────────
-- Test runner
-- ─────────────────────────────────────────────────────────────────────────────

runTests :: IO ()
runTests = do
  putStrLn ""
  putStrLn "══════════════════════════════════════════════"
  putStrLn "  SimulationTest"
  putStrLn "══════════════════════════════════════════════"
  -- Sensitivity
  testModalShareSensitivityDirection
  testEFSensitivityDirection
  testElasticityFormula
  testRunAllSensitivitiesCount
  testSensitivityBaseCO2Matches
  -- PolicyModel / Simulation
  testPredefinedScenariosNonEmpty
  testApplyScenarioSharesSum100
  testRailPushReducesCO2
  testEVTransitionReducesCO2
  testSimulateCityScenarios
  testSimulateAllCities
  testBestScenarioPerCity
  -- TrendAnalysis
  testCo2TrendLength
  testModalShareTrendLength
  testTrendSlopeDecreasing
  testAllCityTrends
  -- ModeAnalysis
  testDominantMode
  testModeShareMatrixSum
  testModeEmissionBreakdownCount
  putStrLn ""
  putStrLn "  ✓ SimulationTest: all tests passed."
  putStrLn ""

-- ─────────────────────────────────────────────────────────────────────────────
-- Sensitivity tests
-- ─────────────────────────────────────────────────────────────────────────────

testModalShareSensitivityDirection :: IO ()
testModalShareSensitivityDirection =
  testCase "modalShareSensitivity: +5pp Car → higher CO2" $ do
    let s = modalShareSensitivity 5.0 Car cityRecs2020
    assertTrue "new CO2 > base CO2" (srNewCO2 s > srBaseCO2 s)

testEFSensitivityDirection :: IO ()
testEFSensitivityDirection =
  testCase "efSensitivity: +10% Car EF → higher CO2" $ do
    let s = efSensitivity 0.10 Car cityRecs2020
    assertTrue "new CO2 > base CO2" (srNewCO2 s > srBaseCO2 s)

testElasticityFormula :: IO ()
testElasticityFormula =
  testCase "elasticity: (dOut/Out) / (dIn/In) is well-defined" $ do
    -- base=4, new=5, baseIn=100, dIn=10 → pctOut=0.25, pctIn=0.1 → e=2.5
    let e = elasticity 4.0 5.0 100.0 10.0
    assertClose "elasticity" 2.5 e

testRunAllSensitivitiesCount :: IO ()
testRunAllSensitivitiesCount =
  testCase "runAllSensitivities: 7 modal + 3 EF = 10 results" $ do
    let results = runAllSensitivities cityRecs2020
    assertEqual "count" 10 (length results)

testSensitivityBaseCO2Matches :: IO ()
testSensitivityBaseCO2Matches =
  testCase "modalShareSensitivity: srBaseCO2 matches cityTotalCO2" $ do
    let s = modalShareSensitivity 5.0 Rail cityRecs2020
    assertClose "base CO2" (cityTotalCO2 cityRecs2020) (srBaseCO2 s)

-- ─────────────────────────────────────────────────────────────────────────────
-- PolicyModel / Simulation tests
-- ─────────────────────────────────────────────────────────────────────────────

testPredefinedScenariosNonEmpty :: IO ()
testPredefinedScenariosNonEmpty =
  testCase "predefinedScenarios: at least 3 scenarios defined" $
    assertTrue "≥3" (length predefinedScenarios >= 3)

testApplyScenarioSharesSum100 :: IO ()
testApplyScenarioSharesSum100 =
  testCase "applyScenario: modal shares sum to 100 after application" $ do
    let scen    = head predefinedScenarios
        shifted = applyScenario scen cityRecs2020
        total   = sum (map trModalShare shifted)
    assertClose "total shares" 100.0 total

testRailPushReducesCO2 :: IO ()
testRailPushReducesCO2 =
  testCase "Rail Push scenario: CO2 decreases (high-car city)" $ do
    let railScen = head [ s | s <- predefinedScenarios, psName s == "Rail Push" ]
        result   = runScenarioForCity railScen "SynCity" 2020 twoYearRecs
    assertTrue "CO2 reduced" (scNewCO2 result < scBaseCO2 result)

testEVTransitionReducesCO2 :: IO ()
testEVTransitionReducesCO2 =
  testCase "EV Transition scenario: CO2 decreases" $ do
    let evScen = head [ s | s <- predefinedScenarios, psName s == "EV Transition" ]
        result = runScenarioForCity evScen "SynCity" 2020 twoYearRecs
    assertTrue "CO2 reduced" (scNewCO2 result < scBaseCO2 result)

testSimulateCityScenarios :: IO ()
testSimulateCityScenarios =
  testCase "simulateCityScenarios: one result per predefined scenario" $ do
    let results = simulateCityScenarios "SynCity" 2020 twoYearRecs
    assertEqual "count" (length predefinedScenarios) (length results)

testSimulateAllCities :: IO ()
testSimulateAllCities =
  testCase "simulateAllCities: results = cities × years × scenarios" $ do
    let results = simulateAllCities twoYearRecs
        cities  = getCities twoYearRecs
        -- 1 city × 2 years × N scenarios
        expected = length cities * 2 * length predefinedScenarios
    assertEqual "count" expected (length results)

testBestScenarioPerCity :: IO ()
testBestScenarioPerCity =
  testCase "bestScenarioPerCity: one entry per city-year" $ do
    let bests = bestScenarioPerCity twoYearRecs
    -- 1 city × 2 years
    assertEqual "count" 2 (length bests)
    -- the best scenario should have CO2 ≤ baseline
    assertTrue "best reduces CO2"
      (all (\(_,_,r) -> scNewCO2 r <= scBaseCO2 r + 1e-9) bests)

-- ─────────────────────────────────────────────────────────────────────────────
-- TrendAnalysis tests
-- ─────────────────────────────────────────────────────────────────────────────

testCo2TrendLength :: IO ()
testCo2TrendLength =
  testCase "co2Trend: one TrendPoint per year in CityMetrics" $ do
    let metrics = aggregateAll twoYearRecs
        pts     = co2Trend "SynCity" metrics
    assertEqual "trend points" 2 (length pts)

testModalShareTrendLength :: IO ()
testModalShareTrendLength =
  testCase "modalShareTrend: one point per year present" $ do
    let pts = modalShareTrend "SynCity" Car twoYearRecs
    assertEqual "trend points" 2 (length pts)

testTrendSlopeDecreasing :: IO ()
testTrendSlopeDecreasing =
  testCase "trendSlope: negative when CO2 decreasing 2015→2020" $ do
    -- 2015: high Car share → high CO2; 2020: lower Car share → lower CO2
    let metrics = aggregateAll twoYearRecs
        pts     = co2Trend "SynCity" metrics
        slope   = trendSlope pts
    assertTrue "slope negative (CO2 falling)" (slope < 0.0)

testAllCityTrends :: IO ()
testAllCityTrends =
  testCase "allCityTrends: one row per distinct city" $ do
    let rows = allCityTrends twoYearRecs
    assertEqual "count" 1 (length rows)   -- one city in twoYearRecs

-- ─────────────────────────────────────────────────────────────────────────────
-- ModeAnalysis tests
-- ─────────────────────────────────────────────────────────────────────────────

testDominantMode :: IO ()
testDominantMode =
  testCase "dominantMode: Car is dominant in high-car city" $
    assertEqual "dominant" (Just Car) (dominantMode "SynCity" 2020 twoYearRecs)

testModeShareMatrixSum :: IO ()
testModeShareMatrixSum =
  testCase "modeShareMatrix: shares sum to ~100" $ do
    let matrix = modeShareMatrix "SynCity" 2020 twoYearRecs
        total  = sum (map snd matrix)
    assertClose "total" 100.0 total

testModeEmissionBreakdownCount :: IO ()
testModeEmissionBreakdownCount =
  testCase "modeEmissionBreakdown: one entry per mode present" $ do
    let bd = modeEmissionBreakdown "SynCity" 2020 twoYearRecs
    -- three modes in our 2020 records
    assertEqual "count" 3 (length bd)

-- ─────────────────────────────────────────────────────────────────────────────
-- Synthetic datasets
-- ─────────────────────────────────────────────────────────────────────────────

-- | Three-mode city-year (2020) used for most tests
cityRecs2020 :: [TransportRecord]
cityRecs2020 =
  [ mk Car        50.0 10.0 0.200 5.0e-4 7.0e-5 2.50
  , mk Rail       30.0 15.0 0.040 9.0e-6 3.0e-6 0.45
  , mk Walk       20.0  1.0 0.000 0.0    0.0    0.00
  ]

-- | Two-year dataset for trend and simulation tests
-- 2015: Car-heavy (CO2 higher); 2020: more Rail (CO2 lower)
twoYearRecs :: [TransportRecord]
twoYearRecs =
  -- 2015: Car 65%, Rail 20%, Walk 15%
  [ (mk Car  65.0 10.0 0.200 5.0e-4 7.0e-5 2.50) { trYear = 2015 }
  , (mk Rail 20.0 15.0 0.040 9.0e-6 3.0e-6 0.45) { trYear = 2015 }
  , (mk Walk 15.0  1.0 0.000 0.0    0.0    0.00) { trYear = 2015 }
  -- 2020: Car 50%, Rail 30%, Walk 20%
  , mk Car  50.0 10.0 0.200 5.0e-4 7.0e-5 2.50
  , mk Rail 30.0 15.0 0.040 9.0e-6 3.0e-6 0.45
  , mk Walk 20.0  1.0 0.000 0.0    0.0    0.00
  ]

mk :: TransportMode -> Double -> Double -> Double -> Double -> Double -> Double
   -> TransportRecord
mk mode share tripKm co2 nox pm10 energy = TransportRecord
  { trCity            = "SynCity"
  , trCountry         = "SynCountry"
  , trContinent       = "SynCont"
  , trPopulation      = 1000000
  , trYear            = 2020
  , trMode            = mode
  , trModalShare      = share
  , trAvgTripKm       = tripKm
  , trDailyTrips      = 4
  , trEfCO2           = co2
  , trEfNOx           = nox
  , trEfPM10          = pm10
  , trEnergyIntensity = energy
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertion helpers
-- ─────────────────────────────────────────────────────────────────────────────

testCase :: String -> IO () -> IO ()
testCase name action = do
  action
  putStrLn $ "  ✓ " ++ name

assertClose :: String -> Double -> Double -> IO ()
assertClose label expected actual
  | abs (expected - actual) < 1e-9 = return ()
  | otherwise = error $
      "FAIL " ++ label ++ ": expected " ++ show expected
               ++ ", got " ++ show actual

assertEqual :: (Eq a, Show a) => String -> a -> a -> IO ()
assertEqual label expected actual
  | expected == actual = return ()
  | otherwise = error $
      "FAIL " ++ label ++ ": expected " ++ show expected
               ++ ", got " ++ show actual

assertTrue :: String -> Bool -> IO ()
assertTrue _     True  = return ()
assertTrue label False = error $ "FAIL " ++ label ++ " is False"
