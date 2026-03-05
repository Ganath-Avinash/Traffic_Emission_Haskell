module CityAggregation where

import Models
import EmissionEngine

cityCO2 :: String -> [TransportRecord] -> Double
cityCO2 cityName records =
  sum [modeCO2 r | r <- records, city r == cityName]