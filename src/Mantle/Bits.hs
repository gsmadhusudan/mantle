{-# LANGUAGE ScopedTypeVariables #-}

module Mantle.Bits where

import Data.Vector.Fixed
import Data.Vector.Fixed.Internal
import Data.Vector.Fixed.Boxed

import Mantle.RTL

class Bits a where
    repType :: a -> VType
    repExpr :: a -> Expr

instance Bits Bool where
    repType _ = BitType 1
    repExpr True  = Lit $ Dec 1
    repExpr False = Lit $ Dec 0

instance Bits Int where
    repType _ = BitType 64 -- TODO: Replace with explicit IntNs
    repExpr = Lit . Dec . toInteger

instance (Arity n, Bits a) => Bits (Vec n a) where
    repType _ = VecType nval arep
      where
        nval = arity   (undefined :: n)
        arep = repType (undefined :: a)
    repExpr v = Concat $ Prelude.map repExpr $ toList v
