module Menu
  ( runMenu
  , menuBanner
  ) where

import Types
import CLI            (runCLI, CLICommand(..))
import Preprocessing  (getCities, getYears, recordsForCityYear)
import System.IO      (hSetBuffering, stdout, BufferMode(..))

-- ─────────────────────────────────────────────────────────────────────────────
-- Entry point
-- ─────────────────────────────────────────────────────────────────────────────

runMenu :: [TransportRecord] -> IO ()
runMenu rs = do
  hSetBuffering stdout NoBuffering
  putStrLn menuBanner
  mainMenu rs

-- ─────────────────────────────────────────────────────────────────────────────
-- Main menu
-- ─────────────────────────────────────────────────────────────────────────────

mainMenu :: [TransportRecord] -> IO ()
mainMenu rs = do
  putStrLn mainMenuText
  putStr "  Enter choice (1-9, 0 to exit): "
  choice <- getLine
  case choice of
    "1" -> runCLI CmdCities        rs >> pause >> mainMenu rs
    "2" -> runCLI CmdGlobal        rs >> pause >> mainMenu rs
    "3" -> runCLI CmdContinent     rs >> pause >> mainMenu rs
    "4" -> runCLI CmdCorrelations  rs >> pause >> mainMenu rs
    "5" -> rankMenu  rs
    "6" -> cityMenu  rs
    "7" -> scenMenu  rs
    "8" -> runCLI CmdBestScenarios rs >> pause >> mainMenu rs
    "9" -> runCLI CmdTrends        rs >> pause >> mainMenu rs
    "0" -> putStrLn "\n  Goodbye.\n"
    _   -> putStrLn "  Invalid choice." >> mainMenu rs

mainMenuText :: String
mainMenuText = unlines
  [ ""
  , "  --------------------------------------------"
  , "                 MAIN MENU                    "
  , "  --------------------------------------------"
  , "   1. City Metrics Overview"
  , "   2. Global Statistics"
  , "   3. Continent Summary"
  , "   4. Correlation Report"
  , "   5. City Rankings"
  , "   6. City Deep-Dive (Report + Sensitivity)"
  , "   7. Scenario Simulation"
  , "   8. Best Scenario Per City"
  , "   9. CO2 Trend Analysis"
  , "   0. Exit"
  , "  --------------------------------------------"
  ]

-- ─────────────────────────────────────────────────────────────────────────────
-- Ranking sub-menu
-- ─────────────────────────────────────────────────────────────────────────────

rankMenu :: [TransportRecord] -> IO ()
rankMenu rs = do
  putStrLn "\n  CITY RANKINGS"
  putStrLn "  ------------------------------------------"
  putStrLn "    1. By CO₂ (lowest first)"
  putStrLn "    2. By Low-Carbon share (highest first)"
  putStrLn "    3. By EV share (highest first)"
  putStrLn "    4. By Energy consumption (lowest first)"
  putStrLn "    0. Back"
  putStr "\n  Choice: "
  sel <- getLine
  case sel of
    "1" -> runCLI CmdRankCO2    rs >> pause >> rankMenu rs
    "2" -> runCLI CmdRankGreen  rs >> pause >> rankMenu rs
    "3" -> runCLI CmdRankEV     rs >> pause >> rankMenu rs
    "4" -> runCLI CmdRankEnergy rs >> pause >> rankMenu rs
    "0" -> mainMenu rs
    _   -> rankMenu rs

-- ─────────────────────────────────────────────────────────────────────────────
-- City deep-dive sub-menu
-- ─────────────────────────────────────────────────────────────────────────────

cityMenu :: [TransportRecord] -> IO ()
cityMenu rs = do
  putStrLn "\n  CITY DEEP-DIVE"
  putStrLn "  ------------------------------------------"
  let cities = getCities rs
  putStrLn "  Select a city:"
  mapM_ (\(i,c) -> putStrLn $ "    " ++ show i ++ ". " ++ c)
        (zip [1 :: Int ..] cities)
  putStrLn "    0. Back"
  putStr "\n  City number: "
  cSel <- getLine
  case reads cSel :: [(Int,String)] of
    [(n,_)] | n == 0                     -> mainMenu rs
    [(n,_)] | n >= 1, n <= length cities -> do
      let city  = cities !! (n-1)
          years = getYears (filter (\r -> trCity r == city) rs)
      yearMenu city years rs
    _ -> cityMenu rs

yearMenu :: String -> [Int] -> [TransportRecord] -> IO ()
yearMenu city years rs = do
  putStrLn $ "\n  City: " ++ city ++ "  — select year:"
  mapM_ (\(i,y) -> putStrLn $ "    " ++ show i ++ ". " ++ show y)
        (zip [1 :: Int ..] years)
  putStrLn "    0. Back"
  putStr "\n  Year: "
  ySel <- getLine
  case reads ySel :: [(Int,String)] of
    [(0,_)] -> cityMenu rs
    [(n,_)] | n >= 1, n <= length years -> do
      let year = years !! (n-1)
      cityDeepDive city year rs
    _ -> yearMenu city years rs

cityDeepDive :: String -> Int -> [TransportRecord] -> IO ()
cityDeepDive city year rs = do
  putStrLn $ "\n  === " ++ city ++ " " ++ show year
          ++ " ═══════════════════════════════════"
  putStrLn "    1. Full City Report"
  putStrLn "    2. Sensitivity Analysis"
  putStrLn "    3. Scenario Simulation"
  putStrLn "    4. Back to city list"
  putStr "\n  Choice: "
  sel <- getLine
  case sel of
    "1" -> runCLI (CmdCity        city year) rs >> pause >> cityDeepDive city year rs
    "2" -> runCLI (CmdSensitivity city year) rs >> pause >> cityDeepDive city year rs
    "3" -> runCLI (CmdScenarios   city year) rs >> pause >> cityDeepDive city year rs
    "4" -> cityMenu rs
    _   -> cityDeepDive city year rs

-- ─────────────────────────────────────────────────────────────────────────────
-- Scenario sub-menu
-- ─────────────────────────────────────────────────────────────────────────────

scenMenu :: [TransportRecord] -> IO ()
scenMenu rs = do
  putStrLn "\n  SCENARIO SIMULATION"
  putStrLn "  ------------------------------------------"
  let cities = getCities rs
  putStrLn "  Select city:"
  mapM_ (\(i,c) -> putStrLn $ "    " ++ show i ++ ". " ++ c)
        (zip [1 :: Int ..] cities)
  putStrLn "    0. Back"
  putStr "\n  City number: "
  cSel <- getLine
  case reads cSel :: [(Int,String)] of
    [(0,_)] -> mainMenu rs
    [(n,_)] | n >= 1, n <= length cities -> do
      let city  = cities !! (n-1)
          years = getYears (filter (\r -> trCity r == city) rs)
      scenYearMenu city years rs
    _ -> scenMenu rs

scenYearMenu :: String -> [Int] -> [TransportRecord] -> IO ()
scenYearMenu city years rs = do
  putStrLn $ "\n  City: " ++ city ++ "  — select year:"
  mapM_ (\(i,y) -> putStrLn $ "    " ++ show i ++ ". " ++ show y)
        (zip [1 :: Int ..] years)
  putStrLn "    0. Back"
  putStr "\n  Year: "
  ySel <- getLine
  case reads ySel :: [(Int,String)] of
    [(0,_)] -> scenMenu rs
    [(n,_)] | n >= 1, n <= length years -> do
      let year = years !! (n-1)
      runCLI (CmdScenarios city year) rs
      pause
      mainMenu rs
    _ -> scenYearMenu city years rs

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

pause :: IO ()
pause = do
  putStr "\n  Press Enter to continue..."
  _ <- getLine
  return ()

menuBanner :: String
menuBanner = unlines
  [ ""
  , "  ================================================================"
  , "                                                                "
  , "     Urban Transport Emissions - Haskell Analysis Engine        "
  , "     Sensitivity of emissions to urban mobility shifts          "
  , "                                                                "
  , "     Dataset  : 8 global cities - 2015 to 2020                  "
  , "     Metrics  : CO2  NOx  PM10  Energy                          "
  , "     Analysis : Sensitivity  Scenarios  Rankings                "
  , "                                                                "
  , "  ================================================================"
  ]