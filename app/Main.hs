module Main where

import Types
import EmissionCalculator

main :: IO ()
main = do
    putStrLn "=== Transport Emissions Calculator ==="

    putStrLn "Enter city name:"
    cityName <- getLine

    putStrLn "Enter population:"
    popInput <- getLine
    let popVal = read popInput :: Int

    putStrLn "Enter number of vehicles:"
    vehInput <- getLine
    let vehVal = read vehInput :: Int

    putStrLn "Enter emission per vehicle:"
    emInput <- getLine
    let emission = read emInput :: Double

    let city = City cityName popVal vehVal emission

    let total = totalEmission city
    let perCap = perCapitaEmission city

    putStrLn "\n--- Emission Results ---"
    putStrLn ("City: " ++ cityName)
    putStrLn ("Total Emission: " ++ show total)
    putStrLn ("Per Capita Emission: " ++ show perCap)