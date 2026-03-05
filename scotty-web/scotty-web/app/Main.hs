{-# LANGUAGE OverloadedStrings #-}

import Web.Scotty

main :: IO ()
main = scotty 3000 $ do
    get "/" $ do
        html "<!DOCTYPE html>\
        \<html>\
        \<head>\
        \    <title>Scotty Server</title>\
        \    <style>\
        \        body {\
        \            font-family: Arial, sans-serif;\
        \            background: linear-gradient(135deg,#0f2027,#203a43,#2c5364);\
        \            color: white;\
        \            text-align: center;\
        \            height: 100vh;\
        \            display: flex;\
        \            align-items: center;\
        \            justify-content: center;\
        \            margin: 0;\
        \        }\
        \        .card {\
        \            background: rgba(255,255,255,0.1);\
        \            padding: 40px;\
        \            border-radius: 12px;\
        \            box-shadow: 0 10px 25px rgba(0,0,0,0.4);\
        \        }\
        \        h1 {\
        \            font-size: 42px;\
        \            margin-bottom: 10px;\
        \        }\
        \        p {\
        \            font-size: 18px;\
        \            opacity: 0.9;\
        \        }\
        \    </style>\
        \</head>\
        \<body>\
        \    <div class='card'>\
        \        <h1>🚀 Scotty Server Running</h1>\
        \        <p>Welcome Kavin</p>\
        \        <p>Your Haskell web server is alive on port 3000.</p>\
        \    </div>\
        \</body>\
        \</html>"