module EmissionCalculator where

import Types

-- Calculate total emissions of a city
totalEmission :: City -> Double
totalEmission city =
    fromIntegral (vehicles city) * emissionPerVehicle city

-- Calculate per capita emission
perCapitaEmission :: City -> Double
perCapitaEmission city =
    totalEmission city / fromIntegral (population city)