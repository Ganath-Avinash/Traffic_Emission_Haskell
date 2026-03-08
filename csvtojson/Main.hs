{-# LANGUAGE OverloadedStrings #-}

import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString as BS
import qualified Data.Csv as Csv
import qualified Data.Vector as V
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Key as Key
import qualified Data.Aeson.KeyMap as KM
import qualified Data.Text.Encoding as TE
import qualified Data.HashMap.Strict as HM

main :: IO ()
main = do
    csvData <- BL.readFile "data/eu_transport.csv"

    case Csv.decodeByName csvData of
        Left err -> putStrLn err
        Right (header, records) -> do
            let headers = V.toList header
                json = Aeson.encode $ map (rowToObject headers) (V.toList records)
            BL.writeFile "data/jsonfile/eu_transport.json" json


rowToObject :: [Csv.Name] -> Csv.NamedRecord -> Aeson.Value
rowToObject headers record =
    Aeson.Object $
        KM.fromList
        [ ( Key.fromText (TE.decodeUtf8 h)
          , Aeson.String (TE.decodeUtf8 (record HM.! h))
          )
        | h <- headers
        ]