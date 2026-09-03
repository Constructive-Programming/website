{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

genInt :: Gen Int
genInt = Gen.int (Range.linear (-30) 30)

prop_agrees :: Property
prop_agrees = property $ do
  b  <- forAll genInt
  bn <- forAll genInt
  am <- forAll genInt
  let before = Before.withdraw (Before.Account b bn) am
      after  = After.withdraw (After.Account b bn) am
  (Before.balance before, Before.bonus before)
    === (After.balance after, After.bonus after)

-- A lens has to satisfy the three equations; they are exactly what
-- makes replacing a field with a get/set pair a refactoring.
prop_laws :: Property
prop_laws = property $ do
  b  <- forAll genInt
  bn <- forAll genInt
  v1 <- forAll genInt
  v2 <- forAll genInt
  let l = After.balanceLens
      a = After.Account b bn
  After.set l (After.get l a) a === a
  After.get l (After.set l v1 a) === v1
  After.set l v2 (After.set l v1 a) === After.set l v2 a

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("withdraw: Before == After", prop_agrees)
    , ("balance lens obeys get-put, put-get, put-put", prop_laws)
    ]
  unless ok exitFailure
