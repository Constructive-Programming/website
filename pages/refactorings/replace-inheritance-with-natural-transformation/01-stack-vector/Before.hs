-- Editor history: apply edits and undos, then list the survivors
-- oldest-first. A Stack is-a list, so the whole list API is the
-- history's API: undo is list surgery like any other operation.
module Before where

import Data.List (foldl')

type Stack a = [a]

data Cmd = Edit String | Undo

build :: [Cmd] -> Stack String
build = foldl' step []
  where
    step h (Edit t) = h ++ [t]
    step h Undo     = take (length h - 1) h

replay :: [Cmd] -> [String]
replay cmds = build cmds -- compiles: a Stack *is* the list
