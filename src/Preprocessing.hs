module Preprocessing where

import Models

filterCity :: String -> [TransportRecord] -> [TransportRecord]
filterCity cityName records =
  [r | r <- records, city r == cityName]

filterYear :: Int -> [TransportRecord] -> [TransportRecord]
filterYear y records =
  [r | r <- records, year r == y]