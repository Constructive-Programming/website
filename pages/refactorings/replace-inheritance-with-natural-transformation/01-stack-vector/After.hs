-- Editor history: apply edits and undos, then list the survivors
-- oldest-first. Stack owns its discipline; toList is the arrow out.
module After where

import Data.List (foldl')

newtype Stack a = Stack [a] deriving Functor

push :: a -> Stack a -> Stack a
push a (Stack xs) = Stack (xs ++ [a])

undo :: Stack a -> Stack a
undo (Stack xs) = Stack (take (length xs - 1) xs)

toList :: Stack a -> [a] -- natural in a
toList (Stack xs) = xs

data Cmd = Edit String | Undo

build :: [Cmd] -> Stack String
build = foldl' step (Stack [])
  where
    step s (Edit t) = push t s
    step s Undo     = undo s

replay :: [Cmd] -> [String]
replay cmds = toList (build cmds) -- build cmds alone: type error
