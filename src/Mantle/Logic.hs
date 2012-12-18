{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Mantle.Logic where

import Mantle.Prelude

import Data.Set
import Data.Bits
import Data.Bits.Bool
import Data.Vector.Bit

import Mantle.RTL
import Mantle.Circuit

newtype Logic a = Logic { expr :: Expr }

always :: Trigger
always = empty

comb :: Bits a => Logic a -> Circuit (Logic a)
comb (Logic e) = do
    w <- newWire
    addStmt always $ BlockingAssign (wireVar w) e
    return $ readWire w

literal :: Bits a => a -> Logic a
literal x = Logic $ Lit (unpack x)

readWire :: Wire a -> Logic a
readWire = Logic . Var . wireVar

readReg :: Reg a -> Logic a
readReg = Logic . Var . regVar

rd = readReg

unOp :: UnaryOperator -> Logic a -> Logic a
unOp op x = Logic $ UnOp op (expr x)

binOp :: BinaryOperator -> Logic a -> Logic a -> Logic b
binOp op x y = Logic $ BinOp (expr x) op (expr y)

instance Boolean (Logic Bool) where
    true  = literal True
    false = literal False
    notB  = unOp OpNot
    (&&*) = binOp OpAnd
    (||*) = binOp OpOr

type instance BooleanOf (Logic a) = Logic Bool

instance IfB (Logic a) where
    ifB c x y = Logic $ CondE (expr c) (expr x) (expr y)

instance EqB (Logic a) where
    (==*) = binOp OpEqual
    (/=*) = binOp OpNotEq

instance OrdB (Logic a) where
    (<*) = binOp OpLT
    (>*) = binOp OpGT
    (<=*) = binOp OpLTE
    (>=*) = binOp OpGTE

instance (Integral a, Bits a) => Num (Logic a) where
    (+) = binOp OpAdd
    (-) = binOp OpSub
    (*) = binOp OpMul
    negate = unOp OpNegate
    abs x = ifB (x > 0) x (negate x)
    signum x = ifB (x > 0) 1 (ifB (x < 0) (-1) 0)
    fromInteger = literal . fromInteger
