module Simulation
  ( simulateAllCities
  , simulateCityScenarios
  , bestScenarioPerCity
  , PolicyScenario(..)
  , ScenarioResult(..)
  ) where

import Types
import PolicyModel
import Preprocessing (getCities, getYears)
import Data.List (minimumBy)
import Data.Ord (comparing)

-- | Run all predefined scenarios for a specific city+year
simulateCityScenarios :: String -> Int -> [TransportRecord] -> [ScenarioResult]
simulateCityScenarios city year recs =
  [ runScenarioForCity s city year recs | s <- predefinedScenarios ]

-- | Run all scenarios for every city-year combination
simulateAllCities :: [TransportRecord] -> [ScenarioResult]
simulateAllCities recs =
  let cities = getCities recs
      years  = getYears recs
  in [ runScenarioForCity s c y recs
     | c <- cities, y <- years, s <- predefinedScenarios ]

-- | Best scenario (highest CO2 reduction) for each city-year
bestScenarioPerCity :: [TransportRecord] -> [(String, Int, ScenarioResult)]
bestScenarioPerCity recs =
  let cities = getCities recs
      years  = getYears recs
  in [ let results = simulateCityScenarios c y recs
           best    = minimumBy (comparing scNewCO2) results
       in (c, y, best)
     | c <- cities, y <- years
     , not (null (simulateCityScenarios c y recs))
     ]
