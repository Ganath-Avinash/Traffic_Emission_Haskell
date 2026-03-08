{-# LANGUAGE CPP #-}
{-# LANGUAGE NoRebindableSyntax #-}
#if __GLASGOW_HASKELL__ >= 810
{-# OPTIONS_GHC -Wno-prepositive-qualified-module #-}
#endif
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -w #-}
module Paths_scotty_web (
    version,
    getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where


import qualified Control.Exception as Exception
import qualified Data.List as List
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude


#if defined(VERSION_base)

#if MIN_VERSION_base(4,0,0)
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#else
catchIO :: IO a -> (Exception.Exception -> IO a) -> IO a
#endif

#else
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#endif
catchIO = Exception.catch

version :: Version
version = Version [0,1,0,0] []

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir `joinFileName` name)

getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath




bindir, libdir, dynlibdir, datadir, libexecdir, sysconfdir :: FilePath
bindir     = "/home/kavinjs/CH.SC.U4CSE24119/Projects/Traffic_Emission_Haskell/scotty-web/.stack-work/install/x86_64-linux-tinfo6/8588895faa7e76447e9703ef7be78c0788df96cf0bad67a9d68120756adfae2f/9.10.3/bin"
libdir     = "/home/kavinjs/CH.SC.U4CSE24119/Projects/Traffic_Emission_Haskell/scotty-web/.stack-work/install/x86_64-linux-tinfo6/8588895faa7e76447e9703ef7be78c0788df96cf0bad67a9d68120756adfae2f/9.10.3/lib/x86_64-linux-ghc-9.10.3-56e0/scotty-web-0.1.0.0-2TBvBhtgRLBCJ0SrIN6y8m-scotty-web-exe"
dynlibdir  = "/home/kavinjs/CH.SC.U4CSE24119/Projects/Traffic_Emission_Haskell/scotty-web/.stack-work/install/x86_64-linux-tinfo6/8588895faa7e76447e9703ef7be78c0788df96cf0bad67a9d68120756adfae2f/9.10.3/lib/x86_64-linux-ghc-9.10.3-56e0"
datadir    = "/home/kavinjs/CH.SC.U4CSE24119/Projects/Traffic_Emission_Haskell/scotty-web/.stack-work/install/x86_64-linux-tinfo6/8588895faa7e76447e9703ef7be78c0788df96cf0bad67a9d68120756adfae2f/9.10.3/share/x86_64-linux-ghc-9.10.3-56e0/scotty-web-0.1.0.0"
libexecdir = "/home/kavinjs/CH.SC.U4CSE24119/Projects/Traffic_Emission_Haskell/scotty-web/.stack-work/install/x86_64-linux-tinfo6/8588895faa7e76447e9703ef7be78c0788df96cf0bad67a9d68120756adfae2f/9.10.3/libexec/x86_64-linux-ghc-9.10.3-56e0/scotty-web-0.1.0.0"
sysconfdir = "/home/kavinjs/CH.SC.U4CSE24119/Projects/Traffic_Emission_Haskell/scotty-web/.stack-work/install/x86_64-linux-tinfo6/8588895faa7e76447e9703ef7be78c0788df96cf0bad67a9d68120756adfae2f/9.10.3/etc"

getBinDir     = catchIO (getEnv "scotty_web_bindir")     (\_ -> return bindir)
getLibDir     = catchIO (getEnv "scotty_web_libdir")     (\_ -> return libdir)
getDynLibDir  = catchIO (getEnv "scotty_web_dynlibdir")  (\_ -> return dynlibdir)
getDataDir    = catchIO (getEnv "scotty_web_datadir")    (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "scotty_web_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "scotty_web_sysconfdir") (\_ -> return sysconfdir)



joinFileName :: String -> String -> FilePath
joinFileName ""  fname = fname
joinFileName "." fname = fname
joinFileName dir ""    = dir
joinFileName dir fname
  | isPathSeparator (List.last dir) = dir ++ fname
  | otherwise                       = dir ++ pathSeparator : fname

pathSeparator :: Char
pathSeparator = '/'

isPathSeparator :: Char -> Bool
isPathSeparator c = c == '/'
