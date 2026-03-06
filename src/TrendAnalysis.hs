module TrendAnalysis
  ( co2Trend
  , energyTrend
  , modalShareTrend
  , trendSlope
  , allCityTrends
  ) where

import Types
import CityAggregation (aggregateAll)
import Statistics (linearRegression)
import Data.List (sortBy)
import Data.Ord (comparing)

-- | CO2 trend points for a specific city
co2Trend :: String -> [CityMetrics] -> [TrendPoint]
co2Trend city metrics =
  [ TrendPoint city (cmYear m) (cmTotalCO2 m) "CO2"
  | m <- sortBy (comparing cmYear) (filter ((== city) . cmCity) metrics) ]

energyTrend :: String -> [CityMetrics] -> [TrendPoint]
energyTrend city metrics =
  [ TrendPoint city (cmYear m) (cmTotalEnergy m) "Energy"
  | m <- sortBy (comparing cmYear) (filter ((== city) . cmCity) metrics) ]

modalShareTrend :: String -> TransportMode -> [TransportRecord] -> [TrendPoint]
modalShareTrend city mode recs =
  let relevant = sortBy (comparing trYear)
                  [ r | r <- recs, trCity r == city, trMode r == mode ]
  in [ TrendPoint city (trYear r) (trModalShare r) (show mode) | r <- relevant ]

-- | OLS slope of a trend (units per year)
trendSlope :: [TrendPoint] -> Double
trendSlope pts =
  let xs = map (fromIntegral . tpYear) pts
      ys = map tpValue pts
      (_, slope) = linearRegression xs ys
  in slope

-- | Summarise CO2 trends for all cities: (city, slope, 2015val, 2020val)
allCityTrends :: [TransportRecord] -> [(String, Double, Double, Double)]
allCityTrends recs =
  let metrics = aggregateAll recs
      cities  = [cmCity m | m <- metrics, cmYear m == 2015]
  in [ let pts  = co2Trend c metrics
           vals = map tpValue pts
           slp  = trendSlope pts
           v2015 = case filter ((== 2015) . tpYear) pts of { (p:_) -> tpValue p; _ -> 0 }
           v2020 = case filter ((== 2020) . tpYear) pts of { (p:_) -> tpValue p; _ -> 0 }
       in (c, slp, v2015, v2020)
     | c <- cities ]
