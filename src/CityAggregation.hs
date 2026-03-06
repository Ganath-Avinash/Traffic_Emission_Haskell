module CityAggregation
  ( aggregateCity
  , aggregateAll
  , cityYearPairs
  ) where

import Types
import EmissionEngine
import Preprocessing
import Utils (groupByKey)
import Data.List (nub, sort)

-- | Aggregate metrics for one city-year slice
aggregateCity :: [TransportRecord] -> Maybe CityMetrics
aggregateCity [] = Nothing
aggregateCity recs@(r:_) =
  let lowC = sum [ trModalShare x | x <- recs, isLowCarbon (trMode x) ]
      carS  = sum [ trModalShare x | x <- recs, trMode x == Car ]
      railS = sum [ trModalShare x | x <- recs, trMode x == Rail ]
  in Just CityMetrics
       { cmCity           = trCity r
       , cmCountry        = trCountry r
       , cmContinent      = trContinent r
       , cmYear           = trYear r
       , cmPopulation     = trPopulation r
       , cmTotalCO2       = cityTotalCO2 recs
       , cmTotalNOx       = cityTotalNOx recs
       , cmTotalPM10      = cityTotalPM10 recs
       , cmTotalEnergy    = cityTotalEnergy recs
       , cmLowCarbonShare = lowC
       , cmCarShare       = carS
       , cmRailShare      = railS
       }

-- | Aggregate all city-year combinations
aggregateAll :: [TransportRecord] -> [CityMetrics]
aggregateAll recs =
  let pairs = cityYearPairs recs
      slices = [ recordsForCityYear c y recs | (c,y) <- pairs ]
  in [ m | Just m <- map aggregateCity slices ]

-- | All unique (city, year) pairs in dataset
cityYearPairs :: [TransportRecord] -> [(String, Int)]
cityYearPairs recs =
  sort . nub $ [ (trCity r, trYear r) | r <- recs ]
