{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import qualified Data.ByteString.Lazy as BL
import Data.Csv
import GHC.Generics

data Vehicle = Vehicle
  { vid :: Int
  , vtype :: String
  , emission :: Int
  } deriving (Show, Generic)

instance FromNamedRecord Vehicle

main :: IO ()
main = do
  csvData <- BL.readFile "vehicles.csv"
  case decodeByName csvData of
    Left err -> putStrLn err
    Right (_, v) -> mapM_ print v