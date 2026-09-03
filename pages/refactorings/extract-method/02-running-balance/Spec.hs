{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

genAmount, genLimit, genFee :: Gen Int
genAmount = Gen.int (Range.linear (-30) 30)
genLimit  = Gen.int (Range.linear 0 20)
genFee    = Gen.int (Range.linear 1 20)

prop_settle_agrees :: Property
prop_settle_agrees = withTests 500 $ property $ do
  opening <- forAll genAmount
  limit   <- forAll genLimit
  fee     <- forAll genFee
  txs     <- forAll (Gen.list (Range.linear 0 20) genAmount)
  Before.settle opening limit fee txs === After.settle opening limit fee txs

prop_step_is_one_step :: Property
prop_step_is_one_step = withTests 500 $ property $ do
  balance <- forAll genAmount
  limit   <- forAll genLimit
  fee     <- forAll genFee
  tx      <- forAll genAmount
  After.step limit fee balance tx === Before.settle balance limit fee [tx]

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("settle: Before == After", prop_settle_agrees)
    , ("step is settle over a single transaction", prop_step_is_one_step)
    ]
  unless ok exitFailure
