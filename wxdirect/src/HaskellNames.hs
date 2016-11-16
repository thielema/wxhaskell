-----------------------------------------------------------------------------------------
{-| Module      :  HaskellNames
    Copyright   :  (c) Daan Leijen 2003
    License     :  BSD-style

    Maintainer  :  wxhaskell-devel@lists.sourceforge.net
    Stability   :  provisional
    Portability :  portable

    Utility module to create haskell compatible names.
-}
-----------------------------------------------------------------------------------------
module HaskellNames( haskellDeclName
                   , haskellName, haskellTypeName, haskellUnBuiltinTypeName
                   , haskellUnderscoreName, haskellArgName
                   , isBuiltin
                   , getPrologue
                   ) where

import qualified Data.Set as Set
import Data.Char( toLower, toUpper, isLower, isUpper )
import Data.Time( getCurrentTime)
import Data.List( isPrefixOf )

{-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------}
builtinObjects :: Set.Set String
builtinObjects
  = Set.fromList ["wxColour","wxString"]

  {-
    [ "Bitmap"
    , "Brush"
    , "Colour"
    , "Cursor"
    , "DateTime"
    , "Icon"
    , "Font"
    , "FontData"
    , "ListItem"
    , "PageSetupData"
    , "Pen"
    , "PrintData"
    , "PrintDialogData"
    , "TreeItemId"
    ]
   -}

reservedVarNames :: Set.Set String
reservedVarNames
  = Set.fromList
    ["data"
    ,"int"
    ,"init"
    ,"module"
    ,"raise"
    ,"type"
    ,"objectDelete"
    ]

reservedTypeNames :: Set.Set String
reservedTypeNames
  = Set.fromList
    [ "Object"
    , "Managed"
    , "ManagedPtr"
    , "Array"
    , "Date"
    , "Dir"
    , "DllLoader"
    , "Expr"
    , "File"
    , "Point"
    , "Size"
    , "String"
    , "Rect"
    ]


{-----------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------}
haskellDeclName name
  | isPrefixOf "wxMDI" name     = haskellName ("mdi" ++ drop 5 name)
  | isPrefixOf "wxDC_" name     = haskellName ("dc" ++ drop 5 name)
  | isPrefixOf "wxGL" name      = haskellName ("gl" ++ drop 4 name)
  | isPrefixOf "wxSVG" name     = haskellName ("svg" ++ drop 5 name)
  | isPrefixOf "expEVT_" name   = ("wxEVT_" ++ drop 7 name) -- keep underscores
  | isPrefixOf "exp" name       = ("wx"     ++ drop 3 name)
  | isPrefixOf "wxc" name       = haskellName name
  | isPrefixOf "wx" name        = haskellName (drop 2 name)
  | isPrefixOf "ELJ" name       = haskellName ("wxc" ++ drop 3 name)
  | isPrefixOf "DDE" name       = haskellName ("dde" ++ drop 3 name)
  | otherwise                   = haskellName name


haskellArgName name
  = haskellName (dropWhile (=='_') name)

haskellName name
  | Set.member suggested reservedVarNames  = "wx" ++ suggested
  | otherwise                              = suggested
  where
    suggested
      = case name of
          (c:cs)  -> toLower c : filter (/='_') cs
          []      -> "wx"

haskellUnderscoreName name
  | Set.member suggested reservedVarNames  = "wx" ++ suggested
  | otherwise                              = suggested
  where
    suggested
      = case name of
          ('W':'X':cs) -> "wx" ++ cs
          (c:cs)       -> toLower c : cs
          []           -> "wx"


haskellTypeName name
  | isPrefixOf "ELJ" name                   = haskellTypeName ("WXC" ++ drop 3 name)
  | Set.member suggested reservedTypeNames  = "Wx" ++ suggested
  | otherwise                               = suggested
  where
    suggested
      = case name of
          'W':'X':'C':cs -> "WXC" ++ cs
          'w':'x':'c':cs -> "WXC" ++ cs
          'w':'x':cs  -> firstUpper cs
          other       -> firstUpper name

    firstUpper name
      = case name of
          c:cs  | isLower c       -> toUpper c : cs
                | not (isUpper c) -> "Wx" ++ name
                | otherwise       -> name
          []    -> "Wx"

haskellUnBuiltinTypeName name
  | isBuiltin name  = haskellTypeName name ++ "Object"
  | otherwise       = haskellTypeName name

isBuiltin name
  = Set.member name builtinObjects

{-----------------------------------------------------------------------------------------
 Haddock prologue
-----------------------------------------------------------------------------------------}
getPrologue :: String -> String -> String -> [FilePath] -> IO [String]
getPrologue moduleName content contains inputFiles
  = do time <- getCurrentTime
       return (prologue time)
  where
    prologue time
      = [line
        ,"{-|\tModule      :  " ++ moduleName
        ,"\tCopyright   :  Copyright (c) Daan Leijen 2003, 2004"
        ,"\tLicense     :  wxWidgets"
        ,""
        ,"\tMaintainer  :  wxhaskell-devel@lists.sourceforge.net"
        ,"\tStability   :  provisional"
        ,"\tPortability :  portable"
        ,""
        ,"Haskell " ++ content ++ " definitions for the wxWidgets C library (@wxc.dll@)."
        ,""
        ,"Do not edit this file manually!"
        ,"This file was automatically generated by wxDirect on: "
        , ""
        ,"  * @" ++ show time ++ "@"
        ]
        ++
        (if (null inputFiles)
          then []
          else (["","From the files:"] ++ concatMap showFile inputFiles))
        ++
        [""
        ,"And contains " ++ contains
        ,"-}"
        ,line
        ]
      where
        line = replicate 80 '-'

        showFile fname
             = ["","  * @" ++ concatMap escapeSlash fname ++ "@"]

        escapeSlash c
             | c == '/'   = "\\/"
             | c == '\"'  = "\\\""
             | otherwise  = [c]
