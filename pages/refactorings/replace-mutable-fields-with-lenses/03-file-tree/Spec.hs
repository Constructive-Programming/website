{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

genName :: Gen String
genName = ("n" <>) . show <$> Gen.int (Range.linear 0 9)

genSize :: Gen Int
genSize = Gen.int (Range.linear (-20) 20)

genNode :: Int -> Gen Before.Node
genNode depth =
  let leaf = Before.Node <$> genName <*> genSize <*> pure []
  in if depth == 0 then leaf
     else Gen.choice
       [ leaf
       , Before.Node <$> genName <*> genSize
           <*> Gen.list (Range.linear 0 3) (genNode (depth - 1))
       ]

toAfter :: Before.Node -> After.Node
toAfter (Before.Node n s cs) = After.Node n s (map toAfter cs)

-- toAfter maps a whole tree faithfully, so After's result can be
-- compared with the converted Before result.
prop_agrees :: Property
prop_agrees = property $ do
  n  <- forAll (genNode 3)
  by <- forAll genSize
  After.bumpSizes (toAfter n) by === toAfter (Before.bumpSizes n by)

prop_laws :: Property
prop_laws = property $ do
  n  <- forAll (genNode 1)
  v1 <- forAll genSize
  v2 <- forAll genSize
  let l   = After.sizeLens
      m   = toAfter n
  After.get l (After.set l v1 m) === v1
  After.set l (After.get l m) m === m
  After.set l v2 (After.set l v1 m) === After.set l v2 m

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("bumpSizes: Before == After", prop_agrees)
    , ("size lens obeys the laws on generated nodes", prop_laws)
    ]
  unless ok exitFailure
