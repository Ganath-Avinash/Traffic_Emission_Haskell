module Preprocessing
  ( filterByCity
  , filterByYear
  , filterByContinent
  , filterByMode
  , filterByYearRange
  , getCities
  , getYears
  , getContinents
  , getModes
  , recordsForCityYear
  , normaliseShares
  ) where

import Types
import Data.List (nub, sort)

filterByCity :: String -> [TransportRecord] -> [TransportRecord]
filterByCity c = filter ((== c) . trCity)

filterByYear :: Int -> [TransportRecord] -> [TransportRecord]
filterByYear y = filter ((== y) . trYear)

filterByContinent :: String -> [TransportRecord] -> [TransportRecord]
filterByContinent c = filter ((== c) . trContinent)

filterByMode :: TransportMode -> [TransportRecord] -> [TransportRecord]
filterByMode m = filter ((== m) . trMode)

filterByYearRange :: Int -> Int -> [TransportRecord] -> [TransportRecord]
filterByYearRange lo hi = filter (\r -> trYear r >= lo && trYear r <= hi)

getCities :: [TransportRecord] -> [String]
getCities = sort . nub . map trCity

getYears :: [TransportRecord] -> [Int]
getYears = sort . nub . map trYear

getContinents :: [TransportRecord] -> [String]
getContinents = sort . nub . map trContinent

getModes :: [TransportRecord] -> [TransportMode]
getModes = nub . map trMode

-- | All records for a specific city-year combination
recordsForCityYear :: String -> Int -> [TransportRecord] -> [TransportRecord]
recordsForCityYear city year = filter (\r -> trCity r == city && trYear r == year)

-- | Renormalise modal shares so they sum to 100
normaliseShares :: [TransportRecord] -> [TransportRecord]
normaliseShares recs =
  let total = sum (map trModalShare recs)
  in if total == 0 then recs
     else map (\r -> r { trModalShare = trModalShare r / total * 100.0 }) recs
