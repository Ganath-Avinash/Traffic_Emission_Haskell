{-# LANGUAGE OverloadedStrings #-}

module Main where

import Web.Scotty
import qualified Data.ByteString.Lazy as BL

main :: IO ()
main = scotty 3000 $ do

  -- Serve the dashboard
  get "/" $ do
    file "static/index.html"

  -- Serve analysis data as JSON
  get "/analysis" $ do
    jsonData <- liftIO $ BL.readFile "../analysis.json"
    setHeader "Content-Type" "application/json; charset=utf-8"
    setHeader "Access-Control-Allow-Origin" "*"
    raw jsonData