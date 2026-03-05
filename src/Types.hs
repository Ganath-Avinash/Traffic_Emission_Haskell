module Types where

data City = City
  { name :: String
  , population :: Int
  , vehicles :: Int
  , emissionPerVehicle :: Double
  } deriving Show