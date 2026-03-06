module Ranking
  ( rankByCO2
  , rankByLowCarbon
  , rankByEVShare
  , rankByEnergy
  , RankEntry(..)
  ) where

import Types
import CityAggregation (aggregateAll)
import Data.List (sortBy)
import Data.Ord (comparing)

rankBy :: (CityMetrics -> Double) -> String -> Bool -> [TransportRecord] -> [RankEntry]
rankBy metric label descending recs =
  let metrics = aggregateAll recs
      sorted  = if descending
                then sortBy (comparing (negate . metric)) metrics
                else sortBy (comparing metric) metrics
  in zipWith (\i m -> RankEntry
       { reRank  = i
       , reCity  = cmCity m
       , reYear  = cmYear m
       , reScore = metric m
       , reLabel = label
       }) [1..] sorted

rankByCO2 :: [TransportRecord] -> [RankEntry]
rankByCO2 = rankBy cmTotalCO2 "CO2 kg/person/day" False

rankByLowCarbon :: [TransportRecord] -> [RankEntry]
rankByLowCarbon = rankBy cmLowCarbonShare "Low Carbon Share %" True

rankByEVShare :: [TransportRecord] -> [RankEntry]
rankByEVShare recs =
  let metrics = aggregateAll recs
      getEV m = let city = cmCity m
                    yr   = cmYear m
                    evs  = [ trModalShare r | r <- recs, trCity r == city
                            , trYear r == yr, trMode r == ElectricCar ]
                in sum evs
      sorted = sortBy (comparing (negate . getEV)) metrics
  in zipWith (\i m -> RankEntry i (cmCity m) (cmYear m) (getEV m) "EV Share %") [1..] sorted

rankByEnergy :: [TransportRecord] -> [RankEntry]
rankByEnergy = rankBy cmTotalEnergy "Energy MJ/person/day" False
