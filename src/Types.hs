{-# LANGUAGE DeriveGeneric #-}

module Types where

import GHC.Generics (Generic)
import Data.Csv

data TransportRecord = TransportRecord
  { record_id :: Int
  , city :: String
  , country :: String
  , continent :: String
  , population :: Int
  , dev_status :: String
  , grid_type :: String
  , year :: Int
  , transport_mode :: String
  , modal_share_pct :: Double
  , avg_trip_km :: Double
  , daily_trips_per_person :: Int
  , emission_factor_co2_kg_per_pkm :: Double
  , emission_factor_nox_kg_per_pkm :: Double
  , emission_factor_pm10_kg_per_pkm :: Double
  , energy_intensity_MJ_per_pkm :: Double
  , co2_emissions_tonnes :: Double
  , nox_emissions_tonnes :: Double
  , pm10_emissions_tonnes :: Double
  , energy_consumption_TJ :: Double
  } deriving (Show, Generic)

instance FromNamedRecord TransportRecord
instance ToNamedRecord TransportRecord


data City = City
  { cityName :: String
  , cityPop :: Int
  , vehicles :: Int
  , emissionPerVehicle :: Double
  } deriving (Show)