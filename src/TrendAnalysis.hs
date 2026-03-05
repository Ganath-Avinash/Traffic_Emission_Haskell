module TrendAnalysis where

import Models

yearsAvailable :: [TransportRecord] -> [Int]
yearsAvailable records =
  [year r | r <- records]