module EmissionCalculator
  ( dailyCO2PerCapita
  , dailyNOxPerCapita
  , dailyPM10PerCapita
  , dailyEnergyPerCapita
  , emissionContribution
  , pkm
  ) where

import Types

-- | Passenger-kilometres for one record (per person per day)
-- pkm = modalShare/100 * dailyTrips * avgTripKm
pkm :: TransportRecord -> Double
pkm r = (trModalShare r / 100.0) * fromIntegral (trDailyTrips r) * trAvgTripKm r

-- | CO2 contribution of one record (kg per person per day)
-- = ef_co2 (kg/pkm) * pkm
emissionContribution :: (TransportRecord -> Double) -> TransportRecord -> Double
emissionContribution ef r = ef r * pkm r

dailyCO2PerCapita :: TransportRecord -> Double
dailyCO2PerCapita = emissionContribution trEfCO2

dailyNOxPerCapita :: TransportRecord -> Double
dailyNOxPerCapita = emissionContribution trEfNOx

dailyPM10PerCapita :: TransportRecord -> Double
dailyPM10PerCapita = emissionContribution trEfPM10

dailyEnergyPerCapita :: TransportRecord -> Double
dailyEnergyPerCapita = emissionContribution trEnergyIntensity
