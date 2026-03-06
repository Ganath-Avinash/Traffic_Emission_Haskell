module ModeAnalysis
  ( modeShareMatrix
  , modeShifts
  , dominantMode
  , lowCarbonShares
  , modeEmissionBreakdown
  ) where

import Types
import EmissionCalculator (dailyCO2PerCapita)
import EmissionEngine (cityTotalCO2)
import Preprocessing (getCities, recordsForCityYear)
import Data.List (maximumBy, sortBy)
import Data.Ord (comparing)

-- | Modal share for every mode for a given city-year
modeShareMatrix :: String -> Int -> [TransportRecord] -> [(TransportMode, Double)]
modeShareMatrix city year recs =
  let slice = recordsForCityYear city year recs
  in [ (trMode r, trModalShare r) | r <- slice ]

-- | How modal shares changed between two years for a city
modeShifts :: String -> Int -> Int -> [TransportRecord] -> [ModeShiftResult]
modeShifts city y1 y2 recs =
  let s1 = modeShareMatrix city y1 recs
      s2 = modeShareMatrix city y2 recs
      modes = map fst s1
  in [ ModeShiftResult
         { msCity      = city
         , msMode      = m
         , msYearFrom  = y1
         , msYearTo    = y2
         , msShareFrom = lookupShare m s1
         , msShareTo   = lookupShare m s2
         , msChange    = lookupShare m s2 - lookupShare m s1
         }
     | m <- modes ]
  where
    lookupShare m xs = case lookup m xs of { Just v -> v; Nothing -> 0 }

-- | Mode with the highest modal share for a city-year
dominantMode :: String -> Int -> [TransportRecord] -> Maybe TransportMode
dominantMode city year recs =
  let slice = recordsForCityYear city year recs
  in case slice of
       [] -> Nothing
       _  -> Just . trMode $ maximumBy (comparing trModalShare) slice

-- | Low-carbon modal share % per city-year
lowCarbonShares :: [TransportRecord] -> [(String, Int, Double)]
lowCarbonShares recs =
  let cities = getCities recs
      years  = [2015, 2020]
  in [ let slice = recordsForCityYear c y recs
           lc = sum [ trModalShare r | r <- slice, isLowCarbon (trMode r) ]
       in (c, y, lc)
     | c <- cities, y <- years ]

-- | CO2 breakdown by mode for a city-year (mode, kg/person/day, pct of total)
modeEmissionBreakdown :: String -> Int -> [TransportRecord] -> [(TransportMode, Double, Double)]
modeEmissionBreakdown city year recs =
  let slice = recordsForCityYear city year recs
      total = cityTotalCO2 slice
      byMode r = let co2 = dailyCO2PerCapita r
                     pct = if total == 0 then 0 else co2 / total * 100
                 in (trMode r, co2, pct)
  in sortBy (comparing (\(_,v,_) -> negate v)) (map byMode slice)
