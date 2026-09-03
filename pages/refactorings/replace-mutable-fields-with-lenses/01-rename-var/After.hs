-- Same, as one composed optic: the prism matches the Var branch,
-- the lens edits its name, every other shape passes through.
module After where

import Data.Char (toUpper)

data Var   = Var   { vName :: String, vRef :: Int }
  deriving (Eq, Show)
data Expr  = EVar Var | EApp Expr Expr | ELam String Expr
  deriving (Eq, Show)

data Lens s a = Lens { view :: s -> a, set :: (s, a) -> s }

modifyL :: Lens s a -> (a -> a) -> s -> s
modifyL l f s = set l (s, f (view l s))

data Prism s a = Prism
  { preview :: s -> Maybe a
  , review  :: a -> s
  }

modifyP :: Prism s a -> (a -> a) -> s -> s
modifyP p f s = case preview p s of
  Nothing -> s
  Just a  -> review p (f a)

-- A prism followed by a lens: hit -> edit the field;
-- miss -> pass through.
data PartialLens s a = PartialLens
  { plPreview :: s -> Maybe a
  , plModify  :: (a -> a) -> s -> s
  }

composeO :: Prism s m -> Lens m a -> PartialLens s a
composeO p l = PartialLens
  { plPreview = \s -> view l <$> preview p s
  , plModify  = \f s -> case preview p s of
      Nothing -> s
      Just m  -> review p (modifyL l f m)
  }

over :: PartialLens s a -> (a -> a) -> s -> s
over pl = plModify pl

varP :: Prism Expr Var
varP = Prism
  { preview = \e -> case e of EVar v -> Just v; _ -> Nothing
  , review  = EVar
  }

nameL :: Lens Var String
nameL = Lens { view = vName, set = \(v, n) -> v { vName = n } }

varName :: PartialLens Expr String
varName = composeO varP nameL

upperVarName :: Expr -> Expr
upperVarName = over varName (map toUpper)
