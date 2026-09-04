{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

genLines :: Gen [Int]
genLines =
  Gen.list (Range.linear 0 10) (Gen.int (Range.linear (-100) 100))

prop_total_agrees :: Property
prop_total_agrees = property $ do
  lines <- forAll genLines
  Before.total lines === After.total lines

-- The parameter has taken over the global's job: at subtotal 0 the
-- result is exactly the fee handed in, for any fee in the range.
prop_fee_is_parametric :: Property
prop_fee_is_parametric = property $ do
  f <- forAll (Gen.int (Range.linear 0 1000))
  After.fee f 0 === f

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("total: Before == After", prop_total_agrees)
    , ( "the fee parameter controls the whole fee"
      , prop_fee_is_parametric )
    ]
  unless ok exitFailure
