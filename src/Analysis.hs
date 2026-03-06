module Analysis
  ( fullCityReport
  , globalSummary
  , continentSummary
  , correlationReport
  , CityReport(..)
  ) where

import Types
import CityAggregation (aggregateAll)
import EmissionEngine (cityTotalCO2, cityDailyCO2Tonnes)
import ModeAnalysis (modeShifts, modeEmissionBreakdown)
import TrendAnalysis (allCityTrends)
import Statistics (computeStats, pearsonCorrelation)
import Preprocessing (recordsForCityYear, getCities)
import Data.List (sortBy, groupBy)
import Data.Ord (comparing)

data CityReport = CityReport
  { crCity       :: String
  , crYear       :: Int
  , crMetrics    :: CityMetrics
  , crBreakdown  :: [(TransportMode, Double, Double)]
  } deriving (Show)

fullCityReport :: String -> Int -> [TransportRecord] -> Maybe CityReport
fullCityReport city year recs =
  let metrics = aggregateAll recs
      mCity   = filter (\m -> cmCity m == city && cmYear m == year) metrics
  in case mCity of
       (m:_) -> Just CityReport
                  { crCity      = city
                  , crYear      = year
                  , crMetrics   = m
                  , crBreakdown = modeEmissionBreakdown city year recs
                  }
       _ -> Nothing

globalSummary :: [TransportRecord] -> (Stats, Stats, Stats)
globalSummary recs =
  let metrics  = aggregateAll recs
      co2s     = map cmTotalCO2 metrics
      energies = map cmTotalEnergy metrics
      lcShares = map cmLowCarbonShare metrics
  in (computeStats co2s, computeStats energies, computeStats lcShares)

continentSummary :: [TransportRecord] -> [(String, Double, Double, Double)]
continentSummary recs =
  let metrics = aggregateAll recs
      grouped = groupBy (\a b -> cmContinent a == cmContinent b)
                $ sortBy (comparing cmContinent) metrics
  in [ let cont = cmContinent (head g)
           avgCO2   = mean (map cmTotalCO2 g)
           avgEnergy= mean (map cmTotalEnergy g)
           avgLC    = mean (map cmLowCarbonShare g)
       in (cont, avgCO2, avgEnergy, avgLC)
     | g <- grouped ]
  where
    mean [] = 0
    mean xs = sum xs / fromIntegral (length xs)

-- | Correlation: carShare vs CO2, railShare vs CO2
correlationReport :: [TransportRecord] -> [(String, Double)]
correlationReport recs =
  let metrics = aggregateAll recs
      co2     = map cmTotalCO2 metrics
      cars    = map cmCarShare metrics
      rails   = map cmRailShare metrics
      lcs     = map cmLowCarbonShare metrics
      pops    = map (fromIntegral . cmPopulation) metrics
  in [ ("CarShare vs CO2",       pearsonCorrelation cars co2)
     , ("RailShare vs CO2",      pearsonCorrelation rails co2)
     , ("LowCarbonShare vs CO2", pearsonCorrelation lcs co2)
     , ("Population vs CO2",     pearsonCorrelation pops co2)
     ]
