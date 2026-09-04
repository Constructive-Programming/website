-- Number every variable in an expression tree, pre-order, with a
-- fresh-number supply.
module Before where

import Data.IORef (IORef, newIORef, readIORef, writeIORef)
import System.IO.Unsafe (unsafePerformIO)

data Expr = Var String | Lit Int | Add Expr Expr
  deriving (Eq, Show)

supply :: IORef Int
{-# NOINLINE supply #-}
supply = unsafePerformIO (newIORef 0) -- global fresh-number supply

number :: Expr -> IO Expr
number e = do
  writeIORef supply 0
  go e

go :: Expr -> IO Expr
go (Var name) = do
  n <- readIORef supply
  writeIORef supply (n + 1)
  pure (Var (name ++ show n))
go e@(Lit _) = pure e
go (Add l r) = do
  l' <- go l
  r' <- go r
  pure (Add l' r')
