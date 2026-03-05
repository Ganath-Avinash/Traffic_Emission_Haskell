module PolicyModel where

import Models

reduceCarShare :: Double -> Double
reduceCarShare carShare =
  carShare * 0.9

increasePublicTransport :: Double -> Double
increasePublicTransport busShare =
  busShare * 1.1