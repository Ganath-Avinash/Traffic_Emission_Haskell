module Models where

data TransportRecord = TransportRecord
  { city :: String
  , country :: String
  , continent :: String
  , population :: Int
  , year :: Int
  , transportMode :: String
  , modalShare :: Double
  , avgTripKm :: Double
  , dailyTrips :: Int
  , co2Factor :: Double
  , noxFactor :: Double
  , pm10Factor :: Double
  , energyIntensity :: Double
  } deriving (Show)