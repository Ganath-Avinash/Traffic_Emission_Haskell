module EmissionTest (runTests) where

import Types
import EmissionCalculator
  ( pkm, dailyCO2PerCapita, dailyNOxPerCapita
  , dailyPM10PerCapita, dailyEnergyPerCapita, emissionContribution )
import EmissionEngine
  ( cityTotalCO2, cityTotalNOx, cityTotalPM10
  , cityTotalEnergy, modeEmissionShare, cityDailyCO2Tonnes )
import EnergyEngine
  ( cityEnergyProfile, energyIntensityByMode, renewableEnergyProxy )
import Statistics
  ( computeStats, pearsonCorrelation, linearRegression, zScore )
import CityAggregation
  ( aggregateAll, aggregateCity )
import Ranking
  ( rankByCO2, rankByLowCarbon, rankByEVShare, rankByEnergy )

-- ─────────────────────────────────────────────────────────────────────────────
-- Test runner
-- ─────────────────────────────────────────────────────────────────────────────

runTests :: IO ()
runTests = do
  putStrLn ""
  putStrLn "══════════════════════════════════════════════"
  putStrLn "  EmissionTest"
  putStrLn "══════════════════════════════════════════════"
  -- EmissionCalculator
  testPkmCar
  testPkmWalk
  testDailyCO2Car
  testDailyCO2Walk
  testEmissionContributionHigherOrder
  testCityTotalCO2
  testCityTotalNOx
  testCityTotalEnergy
  testCityDailyCO2Tonnes
  testModeEmissionShare
  -- EnergyEngine
  testEnergyIntensityByMode
  testCityEnergyProfile
  testRenewableProxy
  -- Statistics
  testStatsBasic
  testStatsEmpty
  testPearsonPerfect
  testPearsonNegative
  testPearsonZero
  testLinearReg
  testZScore
  -- CityAggregation
  testAggregateCity
  testAggregateAll
  -- Ranking
  testRankByCO2Order
  testRankByLowCarbonOrder
  putStrLn ""
  putStrLn "  ✓ EmissionTest: all tests passed."
  putStrLn ""

-- ─────────────────────────────────────────────────────────────────────────────
-- EmissionCalculator tests
-- ─────────────────────────────────────────────────────────────────────────────

testPkmCar :: IO ()
testPkmCar = testCase "pkm: Car 50% share × 4 trips × 10 km = 20.0" $
  -- (50/100) * 4 * 10 = 20.0
  assertClose "pkm" 20.0 (pkm carRec)

testPkmWalk :: IO ()
testPkmWalk = testCase "pkm: Walk 20% share × 4 trips × 1 km = 0.8" $
  -- (20/100) * 4 * 1 = 0.8
  assertClose "pkm" 0.8 (pkm walkRec)

testDailyCO2Car :: IO ()
testDailyCO2Car = testCase "dailyCO2PerCapita: 20 pkm × 0.2 EF = 4.0 kg/p/d" $
  assertClose "co2" 4.0 (dailyCO2PerCapita carRec)

testDailyCO2Walk :: IO ()
testDailyCO2Walk = testCase "dailyCO2PerCapita: Walk has zero EF → 0.0" $
  assertClose "co2" 0.0 (dailyCO2PerCapita walkRec)

testEmissionContributionHigherOrder :: IO ()
testEmissionContributionHigherOrder =
  testCase "emissionContribution: higher-order application with trEfNOx" $
    -- carRec NOx: (50/100)*4*10 * 5e-4 = 20 * 5e-4 = 0.01
    assertClose "nox" 0.01 (emissionContribution trEfNOx carRec)

testCityTotalCO2 :: IO ()
testCityTotalCO2 = testCase "cityTotalCO2: sum across all modes" $ do
  -- Car: 4.0  Rail: 0.3*15*4*0.04=0.72  Walk: 0.0
  assertClose "total CO2" 4.72 (cityTotalCO2 threeMode)

testCityTotalNOx :: IO ()
testCityTotalNOx = testCase "cityTotalNOx: positive and non-zero" $
  assertTrue "nox > 0" (cityTotalNOx threeMode > 0.0)

testCityTotalEnergy :: IO ()
testCityTotalEnergy = testCase "cityTotalEnergy: Car + Rail (Walk = 0)" $ do
  -- Car: 20*2.5=50  Rail: 18*0.45=8.1  Walk: 0
  assertClose "energy" 58.1 (cityTotalEnergy threeMode)

testCityDailyCO2Tonnes :: IO ()
testCityDailyCO2Tonnes = testCase "cityDailyCO2Tonnes: perCapita × pop / 1000" $ do
  -- 4.72 * 1_000_000 / 1000 = 4720 tonnes/day
  assertClose "tonnes" 4720.0 (cityDailyCO2Tonnes threeMode)

testModeEmissionShare :: IO ()
testModeEmissionShare = testCase "modeEmissionShare: Car CO2 / total CO2 ≈ 4/4.72" $ do
  let expected = 4.0 / 4.72
  assertClose "car share" expected (modeEmissionShare Car threeMode)

-- ─────────────────────────────────────────────────────────────────────────────
-- EnergyEngine tests
-- ─────────────────────────────────────────────────────────────────────────────

testEnergyIntensityByMode :: IO ()
testEnergyIntensityByMode =
  testCase "energyIntensityByMode: one entry per record" $
    assertEqual "count" (length threeMode) (length (energyIntensityByMode threeMode))

testCityEnergyProfile :: IO ()
testCityEnergyProfile = testCase "cityEnergyProfile: total matches cityTotalEnergy" $ do
  let (total, _, _) = cityEnergyProfile threeMode
  assertClose "total" (cityTotalEnergy threeMode) total

testRenewableProxy :: IO ()
testRenewableProxy = testCase "renewableEnergyProxy: = EV modal share (0 here)" $
  assertClose "ev proxy" 0.0 (renewableEnergyProxy threeMode)

-- ─────────────────────────────────────────────────────────────────────────────
-- Statistics tests
-- ─────────────────────────────────────────────────────────────────────────────

testStatsBasic :: IO ()
testStatsBasic = testCase "computeStats [1..5]: mean=3, min=1, max=5, median=3" $ do
  let s = computeStats [1,2,3,4,5]
  assertClose "mean"   3.0 (statMean s)
  assertClose "min"    1.0 (statMin s)
  assertClose "max"    5.0 (statMax s)
  assertClose "median" 3.0 (statMedian s)
  -- pop stddev of [1..5] = sqrt(2)
  assertClose "stddev" (sqrt 2.0) (statStdDev s)

testStatsEmpty :: IO ()
testStatsEmpty = testCase "computeStats []: all zeros (no crash)" $ do
  let s = computeStats []
  assertClose "mean" 0.0 (statMean s)

testPearsonPerfect :: IO ()
testPearsonPerfect = testCase "pearsonCorrelation xs xs = 1.0" $
  assertClose "r" 1.0 (pearsonCorrelation [1,2,3,4,5] [1,2,3,4,5])

testPearsonNegative :: IO ()
testPearsonNegative = testCase "pearsonCorrelation xs (reverse xs) = -1.0" $
  assertClose "r" (-1.0) (pearsonCorrelation [1,2,3,4,5] [5,4,3,2,1])

testPearsonZero :: IO ()
testPearsonZero = testCase "pearsonCorrelation: constant ys → 0.0" $
  assertClose "r" 0.0 (pearsonCorrelation [1,2,3,4,5] [3,3,3,3,3])

testLinearReg :: IO ()
testLinearReg = testCase "linearRegression: y = 2x + 1 → intercept=1, slope=2" $ do
  let xs = [1,2,3,4,5]
      ys = [3,5,7,9,11]  -- y = 2x + 1
      (a, b) = linearRegression xs ys
  assertClose "intercept" 1.0 a
  assertClose "slope"     2.0 b

testZScore :: IO ()
testZScore = testCase "zScore: mean value has z-score 0" $ do
  let s = computeStats [1,2,3,4,5]
  assertClose "z at mean" 0.0 (zScore (statMean s) s)

-- ─────────────────────────────────────────────────────────────────────────────
-- CityAggregation tests
-- ─────────────────────────────────────────────────────────────────────────────

testAggregateCity :: IO ()
testAggregateCity = testCase "aggregateCity: totalCO2 matches cityTotalCO2" $ do
  case aggregateCity threeMode of
    Nothing -> failWith "aggregateCity returned Nothing on non-empty input"
    Just m  -> assertClose "CO2" (cityTotalCO2 threeMode) (cmTotalCO2 m)

testAggregateAll :: IO ()
testAggregateAll = testCase "aggregateAll: one CityMetrics per city-year" $ do
  let rs = threeMode ++ map (\r -> r { trCity = "CityB" }) threeMode
      ms = aggregateAll rs
  assertEqual "count" 2 (length ms)

-- ─────────────────────────────────────────────────────────────────────────────
-- Ranking tests
-- ─────────────────────────────────────────────────────────────────────────────

testRankByCO2Order :: IO ()
testRankByCO2Order = testCase "rankByCO2: rank 1 has lowest CO2" $ do
  -- two cities: threeMode (high Car) vs greenCity (all Walk, zero CO2)
  let rs    = threeMode ++ greenCity
      ranks = rankByCO2 rs
  assertEqual "rank 1 city" "GreenCity" (reCity (head ranks))

testRankByLowCarbonOrder :: IO ()
testRankByLowCarbonOrder = testCase "rankByLowCarbon: rank 1 has highest low-carbon share" $ do
  let rs    = threeMode ++ greenCity
      ranks = rankByLowCarbon rs
  assertEqual "rank 1 city" "GreenCity" (reCity (head ranks))

-- ─────────────────────────────────────────────────────────────────────────────
-- Synthetic datasets
-- ─────────────────────────────────────────────────────────────────────────────

carRec :: TransportRecord
carRec = baseRec
  { trMode        = Car
  , trModalShare  = 50.0
  , trAvgTripKm   = 10.0
  , trDailyTrips  = 4
  , trEfCO2       = 0.2
  , trEfNOx       = 5.0e-4
  , trEfPM10      = 7.0e-5
  , trEnergyIntensity = 2.5
  }

railRec :: TransportRecord
railRec = baseRec
  { trMode        = Rail
  , trModalShare  = 30.0
  , trAvgTripKm   = 15.0
  , trDailyTrips  = 4
  , trEfCO2       = 0.04
  , trEfNOx       = 9.0e-6
  , trEfPM10      = 3.0e-6
  , trEnergyIntensity = 0.45
  }

walkRec :: TransportRecord
walkRec = baseRec
  { trMode        = Walk
  , trModalShare  = 20.0
  , trAvgTripKm   = 1.0
  , trDailyTrips  = 4
  , trEfCO2       = 0.0
  , trEfNOx       = 0.0
  , trEfPM10      = 0.0
  , trEnergyIntensity = 0.0
  }

threeMode :: [TransportRecord]
threeMode = [carRec, railRec, walkRec]

-- All-walking city: zero CO2, 100% low-carbon
greenCity :: [TransportRecord]
greenCity =
  [ baseRec
      { trCity       = "GreenCity"
      , trMode       = Walk
      , trModalShare = 100.0
      , trAvgTripKm  = 1.0
      , trDailyTrips = 4
      , trEfCO2      = 0.0
      , trEfNOx      = 0.0
      , trEfPM10     = 0.0
      , trEnergyIntensity = 0.0
      }
  ]

baseRec :: TransportRecord
baseRec = TransportRecord
  { trCity            = "SynCity"
  , trCountry         = "SynCountry"
  , trContinent       = "SynCont"
  , trPopulation      = 1000000
  , trYear            = 2020
  , trMode            = Car
  , trModalShare      = 50.0
  , trAvgTripKm       = 10.0
  , trDailyTrips      = 4
  , trEfCO2           = 0.2
  , trEfNOx           = 5.0e-4
  , trEfPM10          = 7.0e-5
  , trEnergyIntensity = 2.5
  }

-- ─────────────────────────────────────────────────────────────────────────────
-- Assertion helpers
-- ─────────────────────────────────────────────────────────────────────────────

testCase :: String -> IO () -> IO ()
testCase name action = do
  action
  putStrLn $ "  ✓ " ++ name

failWith :: String -> IO ()
failWith = error . ("FAIL: " ++)

assertClose :: String -> Double -> Double -> IO ()
assertClose label expected actual
  | abs (expected - actual) < 1e-9 = return ()
  | otherwise = error $
      "FAIL " ++ label ++ ": expected " ++ show expected
               ++ ", got " ++ show actual
               ++ "  (|Δ| = " ++ show (abs (expected - actual)) ++ ")"

assertEqual :: (Eq a, Show a) => String -> a -> a -> IO ()
assertEqual label expected actual
  | expected == actual = return ()
  | otherwise = error $
      "FAIL " ++ label ++ ": expected " ++ show expected
               ++ ", got " ++ show actual

assertTrue :: String -> Bool -> IO ()
assertTrue _     True  = return ()
assertTrue label False = error $ "FAIL " ++ label ++ " is False"
