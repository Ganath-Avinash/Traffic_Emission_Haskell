module Main where

import Types
import EmissionCalculator

import qualified Data.ByteString.Lazy as BL
import qualified Data.Vector as V
import Data.Csv (decodeByName, Header)

main :: IO ()
main = menu

menu :: IO ()
menu = do
    putStrLn "\n=== Urban Transport Emissions Modeling System ==="
    putStrLn "1. Calculate base emission"
    putStrLn "2. Simulate mobility shift"
    putStrLn "3. Sensitivity analysis"
    putStrLn "4. Load dataset and show summary"
    putStrLn "5. Exit"

    putStrLn "Enter your choice:"
    choice <- getLine

    case choice of
        "1" -> calculateEmission >> menu
        "2" -> simulateShift >> menu
        "3" -> sensitivityAnalysis >> menu
        "4" -> loadDataset >> menu
        "5" -> putStrLn "Exiting program..."
        _   -> putStrLn "Invalid choice!" >> menu


-- Base Emission Calculation
calculateEmission :: IO ()
calculateEmission = do
    putStrLn "\nEnter city name:"
    cityInput <- getLine

    putStrLn "Enter population:"
    popInput <- getLine
    let popVal = read popInput :: Int

    putStrLn "Enter number of vehicles:"
    vehInput <- getLine
    let vehVal = read vehInput :: Int

    putStrLn "Enter emission per vehicle (tons CO2 per year):"
    emInput <- getLine
    let emission = read emInput :: Double

    let cityData = City cityInput popVal vehVal emission

    let total = totalEmission cityData
    let perCap = perCapitaEmission cityData

    putStrLn "\n--- Base Emission Results ---"
    putStrLn ("City: " ++ cityInput)
    putStrLn ("Total Emission: " ++ show total)
    putStrLn ("Per Capita Emission: " ++ show perCap)


-- Mobility Shift Simulation
simulateShift :: IO ()
simulateShift = do
    putStrLn "\n--- Urban Mobility Shift Simulation ---"

    putStrLn "Enter total vehicles:"
    vehInput <- getLine
    let vehicleCount = read vehInput :: Int

    putStrLn "Enter emission per vehicle (tons CO2):"
    emInput <- getLine
    let emission = read emInput :: Double

    putStrLn "Enter percentage shift from cars to public transport:"
    shiftInput <- getLine
    let shift = (read shiftInput :: Double) / 100

    let shiftedVehicles = round (fromIntegral vehicleCount * shift)
    let remainingVehicles = vehicleCount - shiftedVehicles

    -- assume public transport emits 40% less
    let publicEmission = emission * 0.6

    let originalEmission = fromIntegral vehicleCount * emission

    let newEmission =
            (fromIntegral remainingVehicles * emission)
            + (fromIntegral shiftedVehicles * publicEmission)

    putStrLn "\n--- Simulation Results ---"
    putStrLn ("Original Emission: " ++ show originalEmission)
    putStrLn ("Emission After Mobility Shift: " ++ show newEmission)
    putStrLn ("Reduction: " ++ show (originalEmission - newEmission))


-- Sensitivity Analysis
sensitivityAnalysis :: IO ()
sensitivityAnalysis = do
    putStrLn "\n--- Sensitivity Analysis ---"

    putStrLn "Enter number of vehicles:"
    vehInput <- getLine
    let vehicleCount = read vehInput :: Int

    putStrLn "Enter emission per vehicle:"
    emInput <- getLine
    let emission = read emInput :: Double

    let baseEmission = fromIntegral vehicleCount * emission

    putStrLn ("Base emission: " ++ show baseEmission)

    putStrLn "\nShift %  |  Emission"
    mapM_ (printScenario vehicleCount emission) [5,10..50]


printScenario :: Int -> Double -> Int -> IO ()
printScenario vehicleCount emission shift = do

    let shiftRate = (fromIntegral shift / 100.0) :: Double
    let shifted = round (fromIntegral vehicleCount * shiftRate)

    let publicEmission = emission * 0.6

    let newEmission =
            (fromIntegral (vehicleCount - shifted) * emission)
            + (fromIntegral shifted * publicEmission)

    putStrLn (show shift ++ "%      |  " ++ show newEmission)


-- Load Dataset
loadDataset :: IO ()
loadDataset = do
    putStrLn "\nLoading dataset..."
    csvData <- BL.readFile "transport_data.csv"

    case decodeByName csvData :: Either String (Header, V.Vector TransportRecord) of
        Left err ->
            putStrLn ("Error reading CSV: " ++ err)

        Right (_, records) -> do
            putStrLn "Dataset loaded successfully!"
            putStrLn ("Total records: " ++ show (V.length records))

            putStrLn "\nFirst 5 records:"
            mapM_ print (take 5 (V.toList records))