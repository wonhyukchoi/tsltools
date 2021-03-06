-----------------------------------------------------------------------------
-- |
-- Module      :  TSL.TLSF
-- Maintainer  :  Felix Klein
--
-- TLSF writer, which transforms a TSL formula into TLSF.
--
-----------------------------------------------------------------------------

{-# LANGUAGE RecordWildCards #-}

-----------------------------------------------------------------------------

module TSL.TLSF
  ( toTLSF
  ) where

-----------------------------------------------------------------------------

import TSL.SymbolTable (stName)

import TSL.Specification (Specification(..), toFormula)

import TSL.Logic
  ( Formula(..)
  , SignalTerm(..)
  , checks
  , exactlyOne
  , outputs
  , tlsfFormula
  , updates
  )

import Data.Set (elems, toList, union)

import qualified Data.Set as S (map)

import Data.List (groupBy)

import Data.Function (on)

-----------------------------------------------------------------------------

-- | Creates the LTL under-approximation in TLSF for a given TSL
-- specification.

toTLSF
  :: String -> Specification -> String

toTLSF name Specification{..} = unlines
  [ "INFO {"
  , "  TITLE:       \"Converted TSL Specification: " ++ name ++ "\""
  , "  DESCRIPTION: \"TSL specification, which has been converted to TLSF.\""
  , "  SEMANTICS:   Mealy"
  , "  TARGET:      Mealy"
  , "}"
  , "MAIN {"
  , if null ins
    then ""
    else unlines
      [ "  INPUTS {"
      , concatMap ((++ ";\n") . ("    " ++)) ins ++  "  }"
      ]
  , if null outs
    then ""
    else unlines
      [ "  OUTPUTS {"
      , concatMap ((++ ";\n") . ("    " ++)) outs ++ "  }"
      ]
  , "  GUARANTEE {"
  , "    " ++ toTLSF (And [Globally mutual, formula])  ++ ";"
  , "  }"
  , "}"
  ]

  where
    formula = toFormula assumptions guarantees

    toTLSF =
      tlsfFormula (stName symboltable)

    ins =
        map (toTLSF . Check)
      $ toList
      $ checks formula

    outs =
      map (toTLSF . uncurry Update) upds

    upds =
        elems
      $ union (updates formula)
      $ S.map (\x -> (x, Signal x))
      $ outputs formula

    mutual =
        And
      $ map (exactlyOne . map (uncurry Update))
      $ groupBy ((==) `on` fst) upds

-----------------------------------------------------------------------------
