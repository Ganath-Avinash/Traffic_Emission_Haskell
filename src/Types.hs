module Types where

data TransportMode
  = Car | Motorcycle | ElectricCar | Bus | Rail | Walk | Bicycle
  deriving (Show, Eq, Ord, Enum, Bounded)

parseModeStr :: String -> Maybe TransportMode
parseModeStr "Car"         = Just Car
parseModeStr "Motorcycle"  = Just Motorcycle
parseModeStr "ElectricCar" = Just ElectricCar
parseModeStr "Bus"         = Just Bus
parseModeStr "Rail"        = Just Rail
parseModeStr "Walk"        = Just Walk
parseModeStr "Bicycle"     = Just Bicycle
parseModeStr _             = Nothing

modeLabel :: TransportMode -> String
modeLabel Car         = "Car"
modeLabel Motorcycle  = "Motorcycle"
modeLabel ElectricCar = "Electric Car"
modeLabel Bus         = "Bus"
modeLabel Rail        = "Rail"
modeLabel Walk        = "Walk"
modeLabel Bicycle     = "Bicycle"

isLowCarbon :: TransportMode -> Bool
isLowCarbon Walk        = True
isLowCarbon Bicycle     = True
isLowCarbon Rail        = True
isLowCarbon ElectricCar = True
isLowCarbon _           = False

data TransportRecord = TransportRecord
  { trCity            :: String
  , trCountry         :: String
  , trContinent       :: String
  , trPopulation      :: Int
  , trYear            :: Int
  , trMode            :: TransportMode
  , trModalShare      :: Double
  , trAvgTripKm       :: Double
  , trDailyTrips      :: Int
  , trEfCO2           :: Double
  , trEfNOx           :: Double
  , trEfPM10          :: Double
  , trEnergyIntensity :: Double
  } deriving (Show, Eq)

data CityMetrics = CityMetrics
  { cmCity           :: String
  , cmCountry        :: String
  , cmContinent      :: String
  , cmYear           :: Int
  , cmPopulation     :: Int
  , cmTotalCO2       :: Double
  , cmTotalNOx       :: Double
  , cmTotalPM10      :: Double
  , cmTotalEnergy    :: Double
  , cmLowCarbonShare :: Double
  , cmCarShare       :: Double
  , cmRailShare      :: Double
  } deriving (Show, Eq)

data SensitivityResult = SensitivityResult
  { srCity       :: String
  , srYear       :: Int
  , srMode       :: TransportMode
  , srParameter  :: String
  , srDelta      :: Double
  , srBaseCO2    :: Double
  , srNewCO2     :: Double
  , srElasticity :: Double
  } deriving (Show, Eq)

data PolicyScenario = PolicyScenario
  { psName        :: String
  , psDescription :: String
  , psShifts      :: [(TransportMode, Double)]
  } deriving (Show, Eq)

data ScenarioResult = ScenarioResult
  { scScenario     :: PolicyScenario
  , scCity         :: String
  , scYear         :: Int
  , scBaseCO2      :: Double
  , scNewCO2       :: Double
  , scReductionPct :: Double
  , scBaseEnergy   :: Double
  , scNewEnergy    :: Double
  } deriving (Show, Eq)

data Stats = Stats
  { statMean   :: Double
  , statStdDev :: Double
  , statMin    :: Double
  , statMax    :: Double
  , statMedian :: Double
  } deriving (Show, Eq)

data TrendPoint = TrendPoint
  { tpCity   :: String
  , tpYear   :: Int
  , tpValue  :: Double
  , tpMetric :: String
  } deriving (Show, Eq)

data ModeShiftResult = ModeShiftResult
  { msCity      :: String
  , msMode      :: TransportMode
  , msYearFrom  :: Int
  , msYearTo    :: Int
  , msShareFrom :: Double
  , msShareTo   :: Double
  , msChange    :: Double
  } deriving (Show, Eq)

data RankEntry = RankEntry
  { reRank  :: Int
  , reCity  :: String
  , reYear  :: Int
  , reScore :: Double
  , reLabel :: String
  } deriving (Show, Eq)