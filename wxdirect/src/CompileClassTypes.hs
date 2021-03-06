-----------------------------------------------------------------------------------------
{-| Module      :  CompileClassTypes
    Copyright   :  (c) Daan Leijen 2003, 2004
    License     :  BSD-style

    Maintainer  :  wxhaskell-devel@lists.sourceforge.net
    Stability   :  provisional
    Portability :  portable

    Module that compiles classes to class type definitions to Haskell.
-}
-----------------------------------------------------------------------------------------
module CompileClassTypes( compileClassTypes ) where

import qualified Data.Map as Map

import Data.Time( getCurrentTime)
import Types
import HaskellNames
import Classes( isClassName, haskellClassDefs )
import DeriveTypes( ClassName )
import IOExtra

{-----------------------------------------------------------------------------------------
  Compile
-----------------------------------------------------------------------------------------}
compileClassTypes :: Bool -> String -> String -> FilePath -> [FilePath] -> IO ()
compileClassTypes showIgnore moduleRoot moduleName outputFile inputFiles
  = do time    <- getCurrentTime
       let (exportsClass,classDecls) = haskellClassDefs
           exportsClassClasses       = exportDefs exportsClass 

           classCount   = length exportsClass
           
           export   = concat  [ ["module " ++ moduleRoot ++ moduleName
                                , "    ( -- * Version"
                                , "      classTypesVersion"
                                , "      -- * Classes" ]
                              , exportsClassClasses
                              , [ "    ) where"
                                , ""
                                , "import " ++ moduleRoot ++ "WxcObject"
                                , ""
                                , "classTypesVersion :: String"
                                , "classTypesVersion  = \"" ++ show time ++ "\""
                                , "" ]
                              ]

       prologue <- getPrologue moduleName "class"
                               (show classCount ++ " class definitions.")
                               inputFiles
       let output  = unlines (prologue ++ export ++ classDecls)

       putStrLn ("generating: " ++ outputFile)
       writeFileLazy outputFile output
       putStrLn ("generated " ++ show classCount ++ " class definitions.")
       putStrLn ("ok.")


{-----------------------------------------------------------------------------------------
   Create export definitions
-----------------------------------------------------------------------------------------}
exportDefs :: [(ClassName,[String])] -> [String]
exportDefs classExports 
  = let classMap = Map.fromListWith (++) classExports         
    in  concatMap exportDef (Map.toAscList classMap)
  where
    exportDef (className,exports)
      = [heading 2 className] ++ commaSep exports

    commaSep xs
      = map (exportComma++) xs

    heading i name
      = exportSpaces ++ "-- " ++ replicate i '*' ++ " " ++ name

    exportComma  = exportSpaces ++ ","
    exportSpaces = "     "

