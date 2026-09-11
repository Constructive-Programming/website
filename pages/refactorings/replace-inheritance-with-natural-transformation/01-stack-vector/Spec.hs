{-# LANGUAGE OverloadedStrings #-}
module Main where

import Control.Monad (unless)
import System.Exit (exitFailure)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range
import qualified Before
import qualified After

-- A script as raw data: Just text is an edit, Nothing an undo, so
-- one generated script feeds Before.Cmd and After.Cmd alike.
-- Short scripts with frequent undos hit the empty history often.
genScript :: Gen [Maybe String]
genScript = Gen.list (Range.linear 0 20) $ Gen.choice
  [ Just <$> Gen.string (Range.linear 0 6) Gen.alpha
  , pure Nothing
  ]

beforeCmd :: Maybe String -> Before.Cmd
beforeCmd = maybe Before.Undo Before.Edit

afterCmd :: Maybe String -> After.Cmd
afterCmd = maybe After.Undo After.Edit

prop_replay_agrees :: Property
prop_replay_agrees = property $ do
  s <- forAll genScript
  Before.replay (map beforeCmd s) === After.replay (map afterCmd s)

prop_toList_natural :: Property
prop_toList_natural = property $ do
  s <- forAll genScript
  let stack = After.build (map afterCmd s)
  After.toList (fmap length stack)
    === map length (After.toList stack)

main :: IO ()
main = do
  ok <- checkParallel $ Group "Props"
    [ ("replay: Before == After", prop_replay_agrees)
    , ("toList is natural in a", prop_toList_natural)
    ]
  unless ok exitFailure
