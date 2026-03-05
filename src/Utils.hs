module Utils where

unique :: Eq a => [a] -> [a]
unique [] = []
unique (x:xs)
  | x `elem` xs = unique xs
  | otherwise = x : unique xs

safeReadDouble :: String -> Double
safeReadDouble s = read s :: Double

safeReadInt :: String -> Int
safeReadInt s = read s :: Int