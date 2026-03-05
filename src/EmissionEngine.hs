module EmissionEngine where

import Models

modeCO2 :: TransportRecord -> Double
modeCO2 r =
  modalShare r *
  avgTripKm r *
  fromIntegral (dailyTrips r) *
  co2Factor r

modeNOx :: TransportRecord -> Double
modeNOx r =
  modalShare r *
  avgTripKm r *
  fromIntegral (dailyTrips r) *
  noxFactor r

modePM10 :: TransportRecord -> Double
modePM10 r =
  modalShare r *
  avgTripKm r *
  fromIntegral (dailyTrips r) *
  pm10Factor r