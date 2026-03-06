module EmissionEngine
  ( cityTotalCO2
  , cityTotalNOx
  , cityTotalPM10
  , cityTotalEnergy
  , modeEmissionShare
  , cityDailyCO2Tonnes
  ) where

import Types
import EmissionCalculator

-- | Sum an emission function over a list of records (kg/person/day)
sumEmission :: (TransportRecord -> Double) -> [TransportRecord] -> Double
sumEmission f = sum . map f

cityTotalCO2 :: [TransportRecord] -> Double
cityTotalCO2 = sumEmission dailyCO2PerCapita

cityTotalNOx :: [TransportRecord] -> Double
cityTotalNOx = sumEmission dailyNOxPerCapita

cityTotalPM10 :: [TransportRecord] -> Double
cityTotalPM10 = sumEmission dailyPM10PerCapita

cityTotalEnergy :: [TransportRecord] -> Double
cityTotalEnergy = sumEmission dailyEnergyPerCapita

-- | Share of total CO2 attributed to a specific mode (0-1)
modeEmissionShare :: TransportMode -> [TransportRecord] -> Double
modeEmissionShare mode recs =
  let total = cityTotalCO2 recs
      modeRecs = filter ((== mode) . trMode) recs
      modeCO2  = cityTotalCO2 modeRecs
  in if total == 0 then 0 else modeCO2 / total

-- | Total daily CO2 in metric tonnes for the whole city population
cityDailyCO2Tonnes :: [TransportRecord] -> Double
cityDailyCO2Tonnes recs =
  case recs of
    [] -> 0
    (r:_) ->
      let perCapita = cityTotalCO2 recs
          pop       = fromIntegral (trPopulation r)
      in perCapita * pop / 1000.0
