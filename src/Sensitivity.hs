module Sensitivity
  ( modalShareSensitivity
  , efSensitivity
  , runAllSensitivities
  , elasticity
  ) where

import Types
import EmissionEngine (cityTotalCO2)
import Utils (safeDiv)

-- | Perturb modal share of one mode by delta pct-points, recompute CO2
modalShareSensitivity :: Double -> TransportMode -> [TransportRecord]
                       -> SensitivityResult
modalShareSensitivity delta mode recs =
  let baseCO2  = cityTotalCO2 recs
      perturbed = map (perturbShare delta mode) recs
      newCO2   = cityTotalCO2 perturbed
      elas     = elasticity baseCO2 newCO2 (modeShare mode recs) delta
      (city, yr) = case recs of
        []    -> ("?", 0)
        (r:_) -> (trCity r, trYear r)
  in SensitivityResult
       { srCity       = city
       , srYear       = yr
       , srMode       = mode
       , srParameter  = "ModalShare"
       , srDelta      = delta
       , srBaseCO2    = baseCO2
       , srNewCO2     = newCO2
       , srElasticity = elas
       }

perturbShare :: Double -> TransportMode -> TransportRecord -> TransportRecord
perturbShare delta mode r
  | trMode r == mode = r { trModalShare = max 0 (trModalShare r + delta) }
  | otherwise        = r

modeShare :: TransportMode -> [TransportRecord] -> Double
modeShare mode recs =
  sum [ trModalShare r | r <- recs, trMode r == mode ]

-- | Perturb emission factor of one mode by relative factor (e.g. 0.1 = +10%)
efSensitivity :: Double -> TransportMode -> [TransportRecord] -> SensitivityResult
efSensitivity relDelta mode recs =
  let baseCO2   = cityTotalCO2 recs
      perturbed = map (perturbEF relDelta mode) recs
      newCO2    = cityTotalCO2 perturbed
      baseEF    = case filter ((== mode) . trMode) recs of
        []    -> 0
        (r:_) -> trEfCO2 r
      elas = elasticity baseCO2 newCO2 baseEF (relDelta * baseEF)
      (city, yr) = case recs of
        []    -> ("?", 0)
        (r:_) -> (trCity r, trYear r)
  in SensitivityResult
       { srCity       = city
       , srYear       = yr
       , srMode       = mode
       , srParameter  = "EF_CO2"
       , srDelta      = relDelta
       , srBaseCO2    = baseCO2
       , srNewCO2     = newCO2
       , srElasticity = elas
       }

perturbEF :: Double -> TransportMode -> TransportRecord -> TransportRecord
perturbEF relDelta mode r
  | trMode r == mode = r { trEfCO2 = trEfCO2 r * (1 + relDelta) }
  | otherwise        = r

-- | Dimensionless elasticity: (dOutput/Output) / (dInput/Input)
elasticity :: Double -> Double -> Double -> Double -> Double
elasticity baseOut newOut baseIn dIn =
  let pctOut = safeDiv (newOut - baseOut) baseOut
      pctIn  = safeDiv dIn baseIn
  in safeDiv pctOut pctIn

-- | Run modal-share sensitivity for all modes, delta = +5 pct-pts
runAllSensitivities :: [TransportRecord] -> [SensitivityResult]
runAllSensitivities recs =
  [ modalShareSensitivity 5.0 m recs | m <- [Car .. Bicycle] ]
  ++ [ efSensitivity 0.1 m recs | m <- [Car, Motorcycle, Bus] ]
