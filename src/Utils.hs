module Utils where

import Data.List (sortBy, groupBy, nub)
import Data.Ord  (comparing)
import Data.Char (toLower)

-- | Safe division
safeDiv :: Double -> Double -> Double
safeDiv _ 0 = 0.0
safeDiv x y = x / y

-- | Round to N decimal places
roundTo :: Int -> Double -> Double
roundTo n x = fromIntegral (round (x * factor) :: Int) / factor
  where factor = 10 ^ n

-- | Group list by a key function
groupByKey :: Ord k => (a -> k) -> [a] -> [[a]]
groupByKey f = groupBy (\a b -> f a == f b) . sortBy (comparing f)

-- | Unique values
unique :: Eq a => [a] -> [a]
unique = nub

-- | Clamp a value between min and max
clamp :: Ord a => a -> a -> a -> a
clamp lo hi x = max lo (min hi x)

-- | Percentage change: (new - old) / old * 100
pctChange :: Double -> Double -> Double
pctChange old new = safeDiv (new - old) old * 100.0

-- | Weighted average
weightedMean :: [(Double, Double)] -> Double
weightedMean [] = 0.0
weightedMean xs =
  let totalW = sum (map snd xs)
  in if totalW == 0 then 0
     else sum [v * w | (v, w) <- xs] / totalW

-- | Normalise list to [0,1]
normalise :: [Double] -> [Double]
normalise [] = []
normalise xs =
  let lo = minimum xs
      hi = maximum xs
      rng = hi - lo
  in if rng == 0 then map (const 0.5) xs
     else map (\x -> (x - lo) / rng) xs

-- | Format double with given decimal places as string
fmtDouble :: Int -> Double -> String
fmtDouble dp x = show (roundTo dp x)

-- | Case-insensitive string compare
ciEq :: String -> String -> Bool
ciEq a b = map toLower a == map toLower b

-- | Split string on delimiter character
splitOn :: Char -> String -> [String]
splitOn _ "" = [""]
splitOn delim str = foldr f [[]] str
  where
    f c (x:xs)
      | c == delim = [] : x : xs
      | otherwise  = (c : x) : xs
    f _ [] = []

-- | Parse a scientific-notation double ("6.55E-05")
parseDouble :: String -> Maybe Double
parseDouble s = case reads s of
  [(v, "")] -> Just v
  _         -> Nothing

-- | Zip with index starting from 1
zipWithIndex :: [a] -> [(Int, a)]
zipWithIndex = zip [1..]
