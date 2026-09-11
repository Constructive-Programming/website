{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

-- Numerals around zero hit both error branches; letter noise
-- covers the unparsable, digit runs the plain positives.
genRaw :: Gen String
genRaw = Gen.choice
  [ show <$> Gen.int (Range.linear (-20) 20)
  , Gen.string (Range.linear 0 4) Gen.alpha
  , Gen.string (Range.linear 1 4) Gen.digit
  ]

prop_quantity_agrees :: Property
prop_quantity_agrees = property $ do
  raw <- forAll genRaw
  Before.quantity raw === After.quantity raw

prop_toMaybe_natural :: Property
prop_toMaybe_natural = property $ do
  raw <- forAll genRaw
  let e = After.parse raw
  After.toMaybe ((* 2) <$> e) === ((* 2) <$> After.toMaybe e)

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("quantity: Before == After", prop_quantity_agrees)
    , ("toMaybe is natural in a", prop_toMaybe_natural)
    ]
  unless ok exitFailure
