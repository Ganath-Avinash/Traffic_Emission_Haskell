module EmissionCalculator where

import Models
import EmissionEngine

calculateCityCO2 :: String -> [TransportRecord] -> Double
calculateCityCO2 c records =
  sum [modeCO2 r | r <- records, city r == c]