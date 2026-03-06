module CLI
  ( runCLI
  , CLICommand(..)
  , parseArgs
  ) where

import Types
import Analysis
  ( fullCityReport
  , globalSummary
  , continentSummary
  , correlationReport
  , CityReport(..)
  )
import CityAggregation
  ( aggregateAll )
import Sensitivity
  ( runAllSensitivities )
import Ranking
  ( rankByCO2, rankByLowCarbon, rankByEVShare, rankByEnergy, RankEntry(..) )
import Simulation
  ( simulateCityScenarios, bestScenarioPerCity
  , PolicyScenario(..), ScenarioResult(..) )
import Preprocessing
  ( recordsForCityYear )
import TrendAnalysis
  ( allCityTrends )
import Utils
  ( fmtDouble )

import Data.List (intercalate, sortBy)
import Data.Ord  (comparing)

--------------------------------------------------
-- Command ADT
--------------------------------------------------

data CLICommand
  = CmdCities
  | CmdCity String Int
  | CmdGlobal
  | CmdContinent
  | CmdCorrelations
  | CmdRankCO2
  | CmdRankGreen
  | CmdRankEV
  | CmdRankEnergy
  | CmdSensitivity String Int
  | CmdScenarios String Int
  | CmdBestScenarios
  | CmdTrends
  | CmdHelp
  deriving (Show, Eq)

--------------------------------------------------
-- Argument Parser
--------------------------------------------------

parseArgs :: [String] -> CLICommand
parseArgs args = case args of
  ("cities"       : _)         -> CmdCities
  ("city"         : c : y : _) -> CmdCity c (read y)
  ("global"       : _)         -> CmdGlobal
  ("continent"    : _)         -> CmdContinent
  ("correlations" : _)         -> CmdCorrelations
  ("rank" : "co2" : _)         -> CmdRankCO2
  ("rank" : "green" : _)       -> CmdRankGreen
  ("rank" : "ev" : _)          -> CmdRankEV
  ("rank" : "energy" : _)      -> CmdRankEnergy
  ("rank" : _)                 -> CmdRankCO2
  ("sensitivity" : c : y : _)  -> CmdSensitivity c (read y)
  ("scenarios" : c : y : _)    -> CmdScenarios c (read y)
  ("best" : _)                 -> CmdBestScenarios
  ("trends" : _)               -> CmdTrends
  _                            -> CmdHelp

--------------------------------------------------
-- CLI Runner
--------------------------------------------------

runCLI :: CLICommand -> [TransportRecord] -> IO ()

runCLI CmdCities rs = do
  let metrics = aggregateAll rs
      hdrs = ["City","Country","Continent","Year","CO2 kg/p/d","Energy MJ/p/d","LowCarbon %"]
      rows = map cityRow (sortBy (comparing cmTotalCO2) metrics)

  putStrLn divider
  putStrLn "CITY METRICS (sorted by CO2)"
  putStrLn divider
  putStr (tableFormat hdrs rows)

  where
    cityRow m =
      [ cmCity m
      , cmCountry m
      , cmContinent m
      , show (cmYear m)
      , fmtDouble 4 (cmTotalCO2 m)
      , fmtDouble 3 (cmTotalEnergy m)
      , fmtDouble 1 (cmLowCarbonShare m)
      ]

runCLI (CmdCity city year) rs = do
  putStrLn divider
  putStrLn $ "CITY REPORT — " ++ city ++ " (" ++ show year ++ ")"
  putStrLn divider

  case fullCityReport city year rs of
    Nothing -> putStrLn "No data found."
    Just r -> do
      let m = crMetrics r
      putStrLn $ "CO2 per capita/day: " ++ fmtDouble 5 (cmTotalCO2 m)
      putStrLn $ "Energy per capita/day: " ++ fmtDouble 3 (cmTotalEnergy m)
      putStrLn $ "Low carbon share: " ++ fmtDouble 2 (cmLowCarbonShare m)

runCLI CmdGlobal rs = do
  let (co2s, energies, lcs) = globalSummary rs
  putStrLn divider
  putStrLn "GLOBAL DATASET SUMMARY"
  putStrLn divider
  putStrLn $ "Mean CO2: " ++ fmtDouble 4 (statMean co2s)
  putStrLn $ "Mean Energy: " ++ fmtDouble 4 (statMean energies)
  putStrLn $ "Mean Low Carbon Share: " ++ fmtDouble 4 (statMean lcs)

runCLI CmdContinent rs = do
  let rows = continentSummary rs
      hdrs = ["Continent","Avg CO2","Avg Energy","Avg LC"]
      tbl = map (\(c,co2,e,lc) ->
            [c, fmtDouble 4 co2, fmtDouble 3 e, fmtDouble 2 lc]) rows
  putStr (tableFormat hdrs tbl)

runCLI CmdCorrelations rs = do
  let corrs = correlationReport rs
  mapM_ (\(l,v) -> putStrLn (padR 25 l ++ fmtDouble 4 v)) corrs

runCLI CmdRankCO2 rs =
  printRanking "CO2 Ranking" (rankByCO2 rs)

runCLI CmdRankGreen rs =
  printRanking "Low Carbon Ranking" (rankByLowCarbon rs)

runCLI CmdRankEV rs =
  printRanking "EV Ranking" (rankByEVShare rs)

runCLI CmdRankEnergy rs =
  printRanking "Energy Ranking" (rankByEnergy rs)

runCLI (CmdSensitivity city year) rs = do
  let recs = recordsForCityYear city year rs
  if null recs
    then putStrLn "No data"
    else do
      let results = runAllSensitivities recs
      print results

runCLI (CmdScenarios city year) rs = do
  let results = simulateCityScenarios city year rs
  print results

runCLI CmdBestScenarios rs =
  print (bestScenarioPerCity rs)

runCLI CmdTrends rs =
  print (allCityTrends rs)

runCLI CmdHelp _ =
  putStr helpText

--------------------------------------------------
-- Ranking printer
--------------------------------------------------

printRanking :: String -> [RankEntry] -> IO ()
printRanking title ranks = do
  putStrLn divider
  putStrLn title
  putStrLn divider

  let hdrs = ["#","City","Year","Score"]
      rows = map (\r ->
        [ show (reRank r)
        , reCity r
        , show (reYear r)
        , fmtDouble 4 (reScore r)
        ]) ranks

  putStr (tableFormat hdrs rows)

--------------------------------------------------
-- Table formatting utilities
--------------------------------------------------

tableFormat :: [String] -> [[String]] -> String
tableFormat hdrs rows =
  let allRows = hdrs : rows
      widths  = map (maximum . map length) (transpose' allRows)
      sep     = intercalate "-+-" (map (`replicate` '-') widths) ++ "\n"
      fmtRow  = intercalate " | " . zipWith pad widths
  in fmtRow hdrs ++ "\n" ++ sep ++ unlines (map fmtRow rows)

pad :: Int -> String -> String
pad n s = s ++ replicate (n - length s) ' '

transpose' :: [[a]] -> [[a]]
transpose' ([]:_) = []
transpose' x = map head x : transpose' (map tail x)

padR :: Int -> String -> String
padR n s = s ++ replicate (n - length s) ' '

divider :: String
divider = replicate 70 '-'

--------------------------------------------------
-- Help text
--------------------------------------------------

helpText :: String
helpText = unlines
  [ "Transport Emissions CLI"
  , "Commands:"
  , "cities"
  , "city <city> <year>"
  , "global"
  , "continent"
  , "correlations"
  , "rank co2|green|ev|energy"
  , "sensitivity <city> <year>"
  , "scenarios <city> <year>"
  , "best"
  , "trends"
  ]