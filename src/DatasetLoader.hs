module DatasetLoader where

import Models

splitComma :: String -> [String]
splitComma "" = [""]
splitComma s =
  case break (== ',') s of
    (first, ',' : rest) -> first : splitComma rest
    (first, "") -> [first]
    (first, _) -> [first]
    
parseRecord :: String -> TransportRecord
parseRecord line =
  case splitComma line of
    [c,ct,cont,pop,y,mode,share,dist,trips,co2,nox,pm10,energy] ->
      TransportRecord
        c
        ct
        cont
        (read pop)
        (read y)
        mode
        (read share)
        (read dist)
        (read trips)
        (read co2)
        (read nox)
        (read pm10)
        (read energy)

    _ -> error ("Invalid CSV row: " ++ line)

loadDataset :: FilePath -> IO [TransportRecord]
loadDataset path = do
  content <- readFile path
  let rows = lines content
  let dataRows =
        case rows of
          [] -> []
          (_:xs) -> xs
  return (map parseRecord dataRows)