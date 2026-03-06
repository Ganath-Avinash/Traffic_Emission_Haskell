module DatasetTest (runTests) where

import Types
import DatasetLoader  (loadCSV)
import Preprocessing
  ( filterByCity, filterByYear, filterByContinent, filterByMode
  , getCities, getYears, getModes, recordsForCityYear, normaliseShares )

-- ─────────────────────────────────────────────────────────────────────────────
-- Test runner
-- ─────────────────────────────────────────────────────────────────────────────

runTests :: IO ()
runTests = do
  putStrLn ""
  putStrLn "══════════════════════════════════════════════"
  putStrLn "  DatasetTest"
  putStrLn "══════════════════════════════════════════════"
  testParseModeValid
  testParseModeUnknown
  testIsLowCarbon
  testFilterByCity
  testFilterByYear
  testFilterByContinent
  testFilterByMode
  testGetCities
  testGetYears
  testGetModes
  testRecordsForCityYear
  testNormaliseShares
  testModalShareSum
  testFieldNames
  putStrLn ""
  putStrLn "  ✓ DatasetTest: all tests passed."
  putStrLn ""

-- ─────────────────────────────────────────────────────────────────────────────
-- Types tests
-- ─────────────────────────────────────────────────────────────────────────────

testParseModeValid :: IO ()
testParseModeValid = testCase "parseModeStr: known modes parse correctly" $ do
  assertEqual "Car"         (Just Car)         (parseModeStr "Car")
  assertEqual "Motorcycle"  (Just Motorcycle)  (parseModeStr "Motorcycle")
  assertEqual "ElectricCar" (Just ElectricCar) (parseModeStr "ElectricCar")
  assertEqual "Bus"         (Just Bus)         (parseModeStr "Bus")
  assertEqual "Rail"        (Just Rail)        (parseModeStr "Rail")
  assertEqual "Walk"        (Just Walk)        (parseModeStr "Walk")
  assertEqual "Bicycle"     (Just Bicycle)     (parseModeStr "Bicycle")

testParseModeUnknown :: IO ()
testParseModeUnknown = testCase "parseModeStr: unknown string → Nothing" $
  assertEqual "Tram" Nothing (parseModeStr "Tram")

testIsLowCarbon :: IO ()
testIsLowCarbon = testCase "isLowCarbon: Walk/Bicycle/Rail/EV = True; Car/Bus/Moto = False" $ do
  assertTrue  "Walk"        (isLowCarbon Walk)
  assertTrue  "Bicycle"     (isLowCarbon Bicycle)
  assertTrue  "Rail"        (isLowCarbon Rail)
  assertTrue  "ElectricCar" (isLowCarbon ElectricCar)
  assertFalse "Car"         (isLowCarbon Car)
  assertFalse "Bus"         (isLowCarbon Bus)
  assertFalse "Motorcycle"  (isLowCarbon Motorcycle)

-- ─────────────────────────────────────────────────────────────────────────────
-- Preprocessing tests
-- ─────────────────────────────────────────────────────────────────────────────

testFilterByCity :: IO ()
testFilterByCity = testCase "filterByCity: returns only matching city" $ do
  let rs   = sampleRecords
      res  = filterByCity "CityA" rs
  assertEqual "count"    2 (length res)
  assertTrue  "all CityA" (all (\r -> trCity r == "CityA") res)

testFilterByYear :: IO ()
testFilterByYear = testCase "filterByYear: returns only matching year" $ do
  let rs  = sampleRecords
      res = filterByYear 2020 rs
  assertEqual "count"      3 (length res)
  assertTrue  "all 2020"   (all (\r -> trYear r == 2020) res)

testFilterByContinent :: IO ()
testFilterByContinent = testCase "filterByContinent: returns only matching continent" $ do
  let rs  = sampleRecords
      res = filterByContinent "Asia" rs
  assertEqual "count"       1 (length res)
  assertTrue  "all Asia"    (all (\r -> trContinent r == "Asia") res)

testFilterByMode :: IO ()
testFilterByMode = testCase "filterByMode: returns only matching mode" $ do
  let rs  = sampleRecords
      res = filterByMode Car rs
  assertEqual "count"      2 (length res)
  assertTrue  "all Car"    (all (\r -> trMode r == Car) res)

testGetCities :: IO ()
testGetCities = testCase "getCities: unique cities" $ do
  let cities = getCities sampleRecords
  assertEqual "count"    2 (length cities)
  assertElem "CityA" cities
  assertElem "CityB" cities

testGetYears :: IO ()
testGetYears = testCase "getYears: unique years" $ do
  let years = getYears sampleRecords
  assertEqual "count"   2 (length years)
  assertElem 2015 years
  assertElem 2020 years

testGetModes :: IO ()
testGetModes = testCase "getModes: unique modes" $ do
  let modes = getModes sampleRecords
  -- sample has Car and Rail
  assertTrue "at least 2 modes" (length modes >= 2)
  assertElem Car modes

testRecordsForCityYear :: IO ()
testRecordsForCityYear = testCase "recordsForCityYear: exact city+year subset" $ do
  let rs  = recordsForCityYear "CityA" 2020 sampleRecords
  assertEqual "count"         1 (length rs)
  assertTrue  "correct city"  (all (\r -> trCity r == "CityA") rs)
  assertTrue  "correct year"  (all (\r -> trYear r == 2020) rs)

testNormaliseShares :: IO ()
testNormaliseShares = testCase "normaliseShares: shares sum to 100 after normalisation" $ do
  -- give deliberately skewed shares
  let rs    = [ baseRec { trMode = Car,  trModalShare = 60.0 }
              , baseRec { trMode = Rail, trModalShare = 20.0 }
              ]
      normed = normaliseShares rs
      total  = sum (map trModalShare normed)
  assertClose "total shares" 100.0 total

testModalShareSum :: IO ()
testModalShareSum = testCase "sample records: modal shares within each city-year ≈ 100" $ do
  let cityYears = [ ("CityA", 2015), ("CityA", 2020), ("CityB", 2020) ]
  mapM_ check cityYears
  where
    check (city, year) = do
      let grp   = recordsForCityYear city year sampleRecords
          total = sum (map trModalShare grp)
      assertClose ("total for " ++ city ++ "/" ++ show year) 100.0 total

testFieldNames :: IO ()
testFieldNames = testCase "TransportRecord: correct field accessor names" $ do
  let r = baseRec
  assertEqual "trCity"            "SynCity"   (trCity r)
  assertEqual "trCountry"         "SynCountry" (trCountry r)
  assertEqual "trContinent"       "SynCont"    (trContinent r)
  assertEqual "trPopulation"      1000000      (trPopulation r)
  assertEqual "trYear"            2020         (trYear r)
  assertEqual "trMode"            Car          (trMode r)
  assertClose "trModalShare"      50.0         (trModalShare r)
  assertClose "trAvgTripKm"       10.0         (trAvgTripKm r)
  assertEqual "trDailyTrips"      4            (trDailyTrips r)
  assertClose "trEfCO2"           0.2          (trEfCO2 r)
  assertClose "trEfNOx"           5.0e-4       (trEfNOx r)
  assertClose "trEfPM10"          7.0e-5       (trEfPM10 r)
  assertClose "trEnergyIntensity" 2.5          (trEnergyIntensity r)

-- ─────────────────────────────────────────────────────────────────────────────
-- Sample data
-- ─────────────────────────────────────────────────────────────────────────────

-- | 5 records across 2 cities, 2 years, multiple modes.
--   Shares within each city-year sum to 100.
sampleRecords :: [TransportRecord]
sampleRecords =
  -- CityA 2015: Car 60 + Rail 40 = 100
  [ baseRec { trCity = "CityA", trContinent = "Europe", trYear = 2015
            , trMode = Car,  trModalShare = 60.0 }
  , baseRec { trCity = "CityA", trContinent = "Europe", trYear = 2015
            , trMode = Rail, trModalShare = 40.0 }
  -- CityA 2020: Car 55 + Rail 45 = 100
  , baseRec { trCity = "CityA", trContinent = "Europe", trYear = 2020
            , trMode = Car,  trModalShare = 55.0 }
  -- CityB 2020: Car 70 + Rail 30 = 100
  , baseRec { trCity = "CityB", trContinent = "Asia",   trYear = 2020
            , trMode = Car,  trModalShare = 70.0 }
  , baseRec { trCity = "CityB", trContinent = "Asia",   trYear = 2020
            , trMode = Rail, trModalShare = 30.0 }
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

assertEqual :: (Eq a, Show a) => String -> a -> a -> IO ()
assertEqual label expected actual
  | expected == actual = return ()
  | otherwise = error $
      "FAIL " ++ label ++ ": expected " ++ show expected
               ++ ", got " ++ show actual

assertClose :: String -> Double -> Double -> IO ()
assertClose label expected actual
  | abs (expected - actual) < 1e-9 = return ()
  | otherwise = error $
      "FAIL " ++ label ++ ": expected " ++ show expected
               ++ ", got " ++ show actual

assertTrue :: String -> Bool -> IO ()
assertTrue _     True  = return ()
assertTrue label False = error $ "FAIL " ++ label ++ " is False"

assertFalse :: String -> Bool -> IO ()
assertFalse _     False = return ()
assertFalse label True  = error $ "FAIL " ++ label ++ " is True"

assertElem :: (Eq a, Show a) => a -> [a] -> IO ()
assertElem x xs
  | x `elem` xs = return ()
  | otherwise   = error $ "FAIL: " ++ show x ++ " not in list"
