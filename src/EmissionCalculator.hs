module EmissionCalculator where

import Types

totalEmission :: City -> Double
totalEmission cityData =
    fromIntegral (vehicles cityData) * emissionPerVehicle cityData

perCapitaEmission :: City -> Double
perCapitaEmission cityData =
    totalEmission cityData / fromIntegral (cityPop cityData)