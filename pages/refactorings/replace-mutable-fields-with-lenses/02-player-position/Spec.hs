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

genId :: Gen String
genId = ("p" <>) . show <$> Gen.int (Range.linear 0 9)

prop_agrees :: Property
prop_agrees = property $ do
  id <- forAll genId
  lv <- forAll genInt
  px <- forAll genInt
  py <- forAll genInt
  dx <- forAll genInt
  dy <- forAll genInt
  let bg = Before.Game lv (Before.Player id px py)
      ag = After.Game lv (After.Player id px py)
      b1 = Before.moveX bg dx
      b2 = Before.moveY bg dy
      a1 = After.moveX ag dx
      a2 = After.moveY ag dy
  (Before.level b1, Before.px (Before.gplayer b1),
   Before.py (Before.gplayer b1))
    === (After.level a1, After.px (After.gplayer a1),
         After.py (After.gplayer a1))
  (Before.level b2, Before.px (Before.gplayer b2),
   Before.py (Before.gplayer b2))
    === (After.level a2, After.px (After.gplayer a2),
         After.py (After.gplayer a2))

-- The composed path is still a lens: get and set through player . x
-- satisfy the three equations.
prop_laws :: Property
prop_laws = property $ do
  id <- forAll genId
  lv <- forAll genInt
  px <- forAll genInt
  py <- forAll genInt
  v1 <- forAll genInt
  v2 <- forAll genInt
  let l = After.playerX
      g = After.Game lv (After.Player id px py)
  After.set l (After.get l g) g === g
  After.get l (After.set l v1 g) === v1
  After.set l v2 (After.set l v1 g) === After.set l v2 g

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("moveX/moveY: Before == After", prop_agrees)
    , ("composed path lens player.x obeys the laws", prop_laws)
    ]
  unless ok exitFailure
