module Ranking where

import Models
import CityAggregation

rankCities :: [String] -> [TransportRecord] -> [(String, Double)]
rankCities cities records =
  [(c, cityCO2 c records) | c <- cities]