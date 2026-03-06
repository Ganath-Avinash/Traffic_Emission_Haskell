module DatasetLoader
  ( loadDataset
  , loadDatasetFromString
  , parseRecord
  ) where

import Types
import Utils (splitOn, parseDouble)
import Data.Maybe (mapMaybe)

-- | Load and parse the CSV from a file path
loadDataset :: FilePath -> IO [TransportRecord]
loadDataset fp = do
  contents <- readFile fp
  return (loadDatasetFromString contents)

-- | Parse CSV string into records (skips header and malformed lines)
loadDatasetFromString :: String -> [TransportRecord]
loadDatasetFromString contents =
  let ls = lines contents
      dataLines = drop 1 ls   -- skip header
  in mapMaybe parseRecord dataLines

-- | Parse a single CSV line into a TransportRecord
-- city,country,continent,population,year,transport_mode,modal_share_pct,
-- avg_trip_km,daily_trips,ef_co2,ef_nox,ef_pm10,energy_intensity
parseRecord :: String -> Maybe TransportRecord
parseRecord line =
  case splitOn ',' line of
    [city, country, continent, pop, yr, mode, share, tripKm,
     dTrips, efCO2, efNOx, efPM10, energy] ->
      do
        population      <- readMaybeInt pop
        year            <- readMaybeInt yr
        transportMode   <- parseModeStr mode
        modalShare      <- parseDouble share
        avgTripKm       <- parseDouble tripKm
        dailyTrips      <- readMaybeInt dTrips
        emCO2           <- parseDouble efCO2
        emNOx           <- parseDouble efNOx
        emPM10          <- parseDouble efPM10
        energyI         <- parseDouble energy
        return TransportRecord
          { trCity            = city
          , trCountry         = country
          , trContinent       = continent
          , trPopulation      = population
          , trYear            = year
          , trMode            = transportMode
          , trModalShare      = modalShare
          , trAvgTripKm       = avgTripKm
          , trDailyTrips      = dailyTrips
          , trEfCO2           = emCO2
          , trEfNOx           = emNOx
          , trEfPM10          = emPM10
          , trEnergyIntensity = energyI
          }
    _ -> Nothing

readMaybeInt :: String -> Maybe Int
readMaybeInt s = case reads s of
  [(n, "")] -> Just n
  _         -> Nothing
