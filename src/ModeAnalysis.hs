module ModeAnalysis where

import Models

modesInCity :: String -> [TransportRecord] -> [String]
modesInCity cityName records =
  [transportMode r | r <- records, city r == cityName]