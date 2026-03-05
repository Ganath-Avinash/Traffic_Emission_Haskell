module EnergyEngine where

import Models

modeEnergy :: TransportRecord -> Double
modeEnergy r =
  modalShare r *
  avgTripKm r *
  fromIntegral (dailyTrips r) *
  energyIntensity r