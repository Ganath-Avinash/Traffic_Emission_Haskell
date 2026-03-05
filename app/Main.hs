module Main where

import Types
import EmissionCalculator

main :: IO ()
main = menu

menu :: IO ()
menu = do
    putStrLn "\n=== Transport Emissions System ==="
    putStrLn "1. Calculate emission"
    putStrLn "2. Compare cities"
    putStrLn "3. Load dataset"
    putStrLn "4. Exit"

    putStrLn "Enter your choice:"
    choice <- getLine

    case choice of
        "1" -> calculateEmission >> menu
        "2" -> compareCities >> menu
        "3" -> loadDataset >> menu
        "4" -> putStrLn "Exiting program..."
        _   -> putStrLn "Invalid choice!" >> menu


calculateEmission :: IO ()
calculateEmission = do
    putStrLn "\nEnter city name:"
    cityName <- getLine

    putStrLn "Enter population:"
    popInput <- getLine
    let popVal = read popInput :: Int

    putStrLn "Enter number of vehicles:"
    vehInput <- getLine
    let vehVal = read vehInput :: Int

    putStrLn "Enter emission per vehicle (tons CO2 per year):"
    emInput <- getLine
    let emission = read emInput :: Double

    let city = City cityName popVal vehVal emission

    let total = totalEmission city
    let perCap = perCapitaEmission city

    putStrLn "\n--- Emission Results ---"
    putStrLn ("City: " ++ cityName)
    putStrLn ("Total Emission: " ++ show total)
    putStrLn ("Per Capita Emission: " ++ show perCap)


compareCities :: IO ()
compareCities = do
    putStrLn "\nCity comparison feature coming soon!"


loadDataset :: IO ()
loadDataset = do
    putStrLn "\nDataset loading feature coming soon!"