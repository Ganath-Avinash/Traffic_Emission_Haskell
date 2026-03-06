module Statistics
  ( computeStats
  , pearsonCorrelation
  , linearRegression
  , zScore
  , Stats(..)
  ) where

import Types (Stats(..))
import Utils (safeDiv)
import Data.List (sort)

computeStats :: [Double] -> Stats
computeStats [] = Stats 0 0 0 0 0
computeStats xs =
  let n    = fromIntegral (length xs) :: Double
      mn   = sum xs / n
      var  = sum [(x - mn)^(2::Int) | x <- xs] / n
      sd   = sqrt var
      sxs  = sort xs
      med  = if odd (length xs)
             then sxs !! (length xs `div` 2)
             else let mid = length xs `div` 2
                  in (sxs !! (mid-1) + sxs !! mid) / 2.0
  in Stats
      { statMean = mn
      , statStdDev = sd
      , statMin = minimum xs
      , statMax = maximum xs
      , statMedian = med
      }

pearsonCorrelation :: [Double] -> [Double] -> Double
pearsonCorrelation xs ys
  | length xs /= length ys || null xs = 0
  | otherwise =
      let n  = fromIntegral (length xs) :: Double
          mx = sum xs / n
          my = sum ys / n
          num  = sum [ (x - mx) * (y - my) | (x,y) <- zip xs ys ]
          denX = sqrt $ sum [ (x - mx)^(2::Int) | x <- xs ]
          denY = sqrt $ sum [ (y - my)^(2::Int) | y <- ys ]
      in safeDiv num (denX * denY)

-- Simple OLS: returns (intercept, slope)
linearRegression :: [Double] -> [Double] -> (Double, Double)
linearRegression xs ys
  | length xs < 2 = (0, 0)
  | otherwise =
      let n   = fromIntegral (length xs) :: Double
          mx  = sum xs / n
          my  = sum ys / n
          num = sum [ (x - mx) * (y - my) | (x,y) <- zip xs ys ]
          den = sum [ (x - mx)^(2::Int) | x <- xs ]
          slope     = safeDiv num den
          intercept = my - slope * mx
      in (intercept, slope)

zScore :: Double -> Stats -> Double
zScore x s = safeDiv (x - statMean s) (statStdDev s)