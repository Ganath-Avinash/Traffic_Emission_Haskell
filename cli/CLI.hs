module CLI where

import DatasetLoader
import CityAggregation
import Menu

runCLI :: IO ()
runCLI = do
  menu
  choice <- getLine

  case choice of
    "1" -> do
      dataset <- loadDataset "data/eu_transport.csv"
      print (length dataset)

    "2" -> do
      dataset <- loadDataset "data/eu_transport.csv"
      print (cityCO2 "Mumbai" dataset)

    "3" -> putStrLn "Exiting..."

    _ -> putStrLn "Invalid option"