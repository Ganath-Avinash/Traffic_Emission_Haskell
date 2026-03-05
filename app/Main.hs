{-# LANGUAGE OverloadedStrings #-}

import Web.Scotty

main = scotty 3000 $ do
  get "/" $ do
    file "static/index.html"
