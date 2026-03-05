module Analysis where

import Models

cities :: [TransportRecord] -> [String]
cities records =
  [city r | r <- records]