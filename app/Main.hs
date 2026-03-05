module Main where

import Types
import EmissionCalculator

main :: IO ()
main = do
    let paris = City "Paris" 2100000 1200000 2.3

    let total = totalEmission paris
    let perCap = perCapitaEmission paris

    putStrLn "City: Paris"
    putStrLn ("Total Emission: " ++ show total)
    putStrLn ("Per Capita Emission: " ++ show perCap)