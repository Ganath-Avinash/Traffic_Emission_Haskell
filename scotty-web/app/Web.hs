{-# LANGUAGE OverloadedStrings #-}

module Main where

import Web.Scotty
import qualified Data.ByteString.Lazy as BL
import qualified Data.Text.Lazy as TL
import Data.List (intercalate, isSuffixOf)
import Data.Char (isSpace)
import Control.Monad (forM_)
import Control.Monad.IO.Class (liftIO)
import System.Environment (lookupEnv)
import System.Directory (listDirectory)
import Text.Read (readMaybe)

main :: IO ()
main = do
  portEnv <- lookupEnv "PORT"
  let port = maybe 3000 id (portEnv >>= readMaybe)

  -- Discover all JSON files in the static folder
  allFiles <- listDirectory "static"
  let jsonFiles = filter (".json" `isSuffixOf`) allFiles
  putStrLn $ "Found JSON files: " ++ show jsonFiles
  putStrLn $ "Starting Scotty server on port " ++ show port

  scotty port $ do

    -- Login page
    get "/" $
      file "static/index.html"

    get "/index.html" $
      file "static/index.html"

    -- Dashboard
    get "/dashboard.html" $
      file "static/dashboard.html"

    -- Dynamically register routes for every JSON file in static/
    forM_ jsonFiles $ \jsonFile -> do
      let baseName    = take (length jsonFile - 5) jsonFile  -- strip ".json"
          filePath    = "static/" ++ jsonFile
          routeFile   = TL.pack $ "/" ++ jsonFile            -- e.g. /analysis.json
          routeName   = TL.pack $ "/" ++ baseName            -- e.g. /analysis
          routeApi    = TL.pack $ "/api/" ++ baseName        -- e.g. /api/analysis

      -- /<name>.json
      get (literal routeFile) $ do
        jsonData <- liftIO $ BL.readFile filePath
        setHeader "Content-Type" "application/json; charset=utf-8"
        setHeader "Access-Control-Allow-Origin" "*"
        raw jsonData

      -- /<name>
      get (literal routeName) $ do
        jsonData <- liftIO $ BL.readFile filePath
        setHeader "Content-Type" "application/json; charset=utf-8"
        setHeader "Access-Control-Allow-Origin" "*"
        raw jsonData

      -- /api/<name>
      get (literal routeApi) $ do
        jsonData <- liftIO $ BL.readFile filePath
        setHeader "Content-Type" "application/json; charset=utf-8"
        setHeader "Access-Control-Allow-Origin" "*"
        raw jsonData


-- CSV → JSON (future use)

csvToJson :: String -> String
csvToJson content =
  let ls       = lines content
      header   = case ls of
                   (h:_) -> splitOn ',' h
                   []    -> []
      dataRows = case ls of
                   (_:rest) -> rest
                   []       -> []
      parsed   = map (rowToJson header . splitOn ',') dataRows
      valid    = filter (not . null) parsed
  in "[" ++ intercalate ",\n" valid ++ "]"


rowToJson :: [String] -> [String] -> String
rowToJson header vals
  | length vals /= length header = ""
  | otherwise =
      let pairs  = zip header vals
          fields = map (\(k,v) -> jsonField k v) pairs
      in "{" ++ intercalate ", " fields ++ "}"


jsonField :: String -> String -> String
jsonField key val =
  let k = "\"" ++ trim key ++ "\""
      v = encodeVal (trim val)
  in k ++ ": " ++ v


encodeVal :: String -> String
encodeVal s
  | isNumeric s = s
  | otherwise   = "\"" ++ escapeJson s ++ "\""


isNumeric :: String -> Bool
isNumeric "" = False
isNumeric s =
  case reads s :: [(Double,String)] of
    [(_, "")] -> True
    _         -> False


escapeJson :: String -> String
escapeJson = concatMap escape
  where
    escape '"'  = "\\\""
    escape '\\' = "\\\\"
    escape c    = [c]


trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace


splitOn :: Char -> String -> [String]
splitOn _ "" = [""]
splitOn delim str =
  foldr f [""] str
  where
    f c (x:xs)
      | c == delim = "" : x : xs
      | otherwise  = (c : x) : xs
    f _ [] = []