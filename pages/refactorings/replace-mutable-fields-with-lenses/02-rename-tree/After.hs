-- Same, with the same varName optic applied at every node of the
-- tree: how to reach the name is defined once, and the walk only
-- decides where it applies.
module After where

import Data.Char (toUpper)
import Optics (Lens(..), Prism(..), PartialLens(..), composeO, over)

data Var = Var { vName :: String, vRef :: Int }
  deriving (Eq, Show)
data Expr = EVar Var | EApp Expr Expr | ELam String Expr
  deriving (Eq, Show)

varP :: Prism Expr Var
varP = Prism
  { preview = \e -> case e of EVar v -> Just v; _ -> Nothing
  , review  = EVar
  }

nameL :: Lens Var String
nameL = Lens { view = vName, set = \(v, n) -> v { vName = n } }

varName :: PartialLens Expr String
varName = composeO varP nameL

-- Bottom-up: apply the rewrite at every node, descending first.
everywhere :: (Expr -> Expr) -> Expr -> Expr
everywhere f e@(EVar _)    = f e
everywhere f (EApp a b)    = f (EApp (everywhere f a) (everywhere f b))
everywhere f (ELam b bd)   = f (ELam b (everywhere f bd))

renameAll :: Expr -> Expr
renameAll = everywhere (over varName (map toUpper))
