module Main where

import DatasetLoader        (loadDataset)
import CLI                  (runCLI, CLICommand(..), parseArgs)
import Menu                 (runMenu, menuBanner)
import System.Environment   (getArgs)
import System.IO            (hPutStrLn, stderr, hSetBuffering, stdout, BufferMode(..))

-- ─────────────────────────────────────────────────────────────────────────────
-- Main entry point
--
-- Usage patterns
-- ──────────────────────────────────────────────────────────────────────────
--   transport-emissions                          → interactive menu
--   transport-emissions help                     → usage text
--   transport-emissions cities                   → city metrics table
--   transport-emissions city Berlin 2020         → city deep report
--   transport-emissions global                   → global statistics
--   transport-emissions continent                → continent summary
--   transport-emissions correlations             → correlation report
--   transport-emissions rank co2                 → CO₂ ranking
--   transport-emissions rank green               → low-carbon ranking
--   transport-emissions rank ev                  → EV share ranking
--   transport-emissions rank energy              → energy ranking
--   transport-emissions sensitivity Berlin 2020  → sensitivity analysis
--   transport-emissions scenarios Berlin 2020    → scenario comparison
--   transport-emissions best                     → best scenario per city
--   transport-emissions trends                   → trend slopes
--
-- If the last argument ends with ".csv" it overrides the default data path.
-- ─────────────────────────────────────────────────────────────────────────────

main :: IO ()
main = do
  hSetBuffering stdout LineBuffering
  args <- getArgs

  let (cmdArgs, csvPath) = extractCsvPath args

  hPutStrLn stderr $ "[transport-emissions] Loading: " ++ csvPath
  records <- loadDataset csvPath
  hPutStrLn stderr $ "[transport-emissions] Loaded " ++ show (length records) ++ " records."

  case cmdArgs of
    -- No arguments → launch interactive menu
    [] -> do
      putStrLn menuBanner
      runMenu records
    -- Any recognised command → run it directly
    _  -> do
      let cmd = parseArgs cmdArgs
      runCLI cmd records

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

-- | Split args into (command-args, csv-path).
--   If the last arg ends with ".csv" it is the data path.
extractCsvPath :: [String] -> ([String], FilePath)
extractCsvPath [] = ([], defaultCSV)
extractCsvPath args
  | ".csv" `isSuffixOf` last args = (init args, last args)
  | otherwise                      = (args, defaultCSV)

defaultCSV :: FilePath
defaultCSV = "data/eu_transport.csv"

isSuffixOf :: String -> String -> Bool
isSuffixOf suffix str =
  length str >= length suffix
  && drop (length str - length suffix) str == suffix