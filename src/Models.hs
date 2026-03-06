module Models
  ( EmissionModel(..)
  , linearModel
  , weightedModel
  , sensitivityModel
  , applyModel
  ) where

import Types
import EmissionCalculator

-- | Higher-order abstraction: an emission model is a function from
-- a list of records to a Double, parameterised by a pollutant selector
newtype EmissionModel = EmissionModel
  { runModel :: [TransportRecord] -> Double }

-- | Linear model: sum over all modes
linearModel :: (TransportRecord -> Double) -> EmissionModel
linearModel ef = EmissionModel (sum . map ef)

-- | Weighted model: weight each mode's emission by a mode-specific factor
weightedModel :: (TransportMode -> Double) -> (TransportRecord -> Double) -> EmissionModel
weightedModel weight ef = EmissionModel $ \recs ->
  sum [ weight (trMode r) * ef r | r <- recs ]

-- | Sensitivity model: perturb a specific parameter and return delta
sensitivityModel :: (TransportRecord -> TransportRecord) -> EmissionModel -> EmissionModel -> EmissionModel
sensitivityModel perturb base alt = EmissionModel $ \recs ->
  runModel alt (map perturb recs) - runModel base recs

-- | Apply a model to a filtered slice
applyModel :: EmissionModel -> [TransportRecord] -> Double
applyModel = runModel

-- | Compose two models (add their outputs)
instance Semigroup EmissionModel where
  EmissionModel f <> EmissionModel g = EmissionModel (\recs -> f recs + g recs)

instance Monoid EmissionModel where
  mempty = EmissionModel (const 0)
