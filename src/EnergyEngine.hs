module EnergyEngine where

import Types

energyUse :: TransportRecord -> Double
energyUse r =
    trModalShare r * trAvgTripKm r * trEnergyIntensity r

totalEnergy :: [TransportRecord] -> Double
totalEnergy = sum . map energyUse