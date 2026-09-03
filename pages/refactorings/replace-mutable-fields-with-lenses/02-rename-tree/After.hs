-- Same, with the same varName optic applied at every node: the walk
-- comes from Plated (which fields recurse), not from the example.
module After where

import Data.Char (toUpper)
import Optics
  ( Lens(..), Prism(..), PartialLens(..), Plated(..)
  , composeO, over, everywhere
  )

data Var = Var { vName :: String, vRef :: Int }
  deriving (Eq, Show)
data Expr = EVar Var | EApp Expr Expr | ELam String Expr
  deriving (Eq, Show)

instance Plated Expr where
  descend f (EApp a b)   = EApp (f a) (f b)
  descend f (ELam b bd)  = ELam b (f bd)
  descend _ e            = e

varP :: Prism Expr Var
varP = Prism
  { preview = \e -> case e of EVar v -> Just v; _ -> Nothing
  , review  = EVar
  }

nameL :: Lens Var String
nameL = Lens { view = vName, set = \(v, n) -> v { vName = n } }

varName :: PartialLens Expr String
varName = composeO varP nameL

renameAll :: Expr -> Expr
renameAll = everywhere (over varName (map toUpper))
