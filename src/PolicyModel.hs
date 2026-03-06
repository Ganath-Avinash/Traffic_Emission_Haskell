module PolicyModel
  ( applyScenario
  , predefinedScenarios
  , runScenarioForCity
  ) where

import Types
import EmissionEngine (cityTotalCO2, cityTotalEnergy)
import Preprocessing (recordsForCityYear)
import Utils (safeDiv, pctChange)
import Data.List (foldl')

-- | Apply a scenario's modal share shifts to a set of records
-- Shifts are applied to the target modes; remaining share is scaled proportionally
applyScenario :: PolicyScenario -> [TransportRecord] -> [TransportRecord]
applyScenario scenario recs =
  let shifted   = foldl' applyShift recs (psShifts scenario)
      totalShifted = sum (map trModalShare shifted)
      scale = if totalShifted == 0 then 1
              else 100.0 / totalShifted
  in map (\r -> r { trModalShare = trModalShare r * scale }) shifted

applyShift :: [TransportRecord] -> (TransportMode, Double) -> [TransportRecord]
applyShift recs (mode, newShare) =
  map (\r -> if trMode r == mode then r { trModalShare = newShare } else r) recs

runScenarioForCity :: PolicyScenario -> String -> Int -> [TransportRecord] -> ScenarioResult
runScenarioForCity scenario city year allRecs =
  let recs      = recordsForCityYear city year allRecs
      baseCO2   = cityTotalCO2 recs
      baseEnergy= cityTotalEnergy recs
      modified  = applyScenario scenario recs
      newCO2    = cityTotalCO2 modified
      newEnergy = cityTotalEnergy modified
      redPct    = pctChange baseCO2 newCO2
  in ScenarioResult
       { scScenario     = scenario
       , scCity         = city
       , scYear         = year
       , scBaseCO2      = baseCO2
       , scNewCO2       = newCO2
       , scReductionPct = redPct
       , scBaseEnergy   = baseEnergy
       , scNewEnergy    = newEnergy
       }

-- | Built-in policy scenarios
predefinedScenarios :: [PolicyScenario]
predefinedScenarios =
  [ PolicyScenario
      { psName        = "Rail Push"
      , psDescription = "Increase rail share by 10 pct-pts, reduce car by 10"
      , psShifts      = [(Rail, 10), (Car, -10)]   -- relative delta approach
      }
  , PolicyScenario
      { psName        = "EV Transition"
      , psDescription = "Double electric car share at expense of conventional car"
      , psShifts      = [(ElectricCar, 10), (Car, -10)]
      }
  , PolicyScenario
      { psName        = "Active Mobility"
      , psDescription = "Increase walk+cycle by 5 pct-pts each, reduce motorcycle by 10"
      , psShifts      = [(Walk, 5), (Bicycle, 5), (Motorcycle, -10)]
      }
  , PolicyScenario
      { psName        = "Bus Rapid Transit"
      , psDescription = "Increase bus share by 8 pct-pts, reduce car by 8"
      , psShifts      = [(Bus, 8), (Car, -8)]
      }
  , PolicyScenario
      { psName        = "Zero Car City"
      , psDescription = "Halve car share, redistribute to Rail and EV"
      , psShifts      = [(Car, -20), (Rail, 10), (ElectricCar, 10)]
      }
  ]
