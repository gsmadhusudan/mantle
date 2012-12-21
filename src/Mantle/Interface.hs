{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE DataKinds #-}

module Mantle.Interface where


import Data.Bits

import Mantle.Circuit


data FaceK = InnerT | OuterT

type Inner ifc = Ifc InnerT ifc
type Outer ifc = Ifc OuterT ifc

class Interface ifc where
    data Ifc (d :: FaceK) ifc
    newIfc :: Circuit (Ifc InnerT ifc)
    expose :: Ifc InnerT ifc -> Ifc OuterT ifc


data Input a
data Output a

instance Bits a => Interface (Input a) where
    data Ifc d (Input a) = InputWire (Wire a)
    newIfc = do
        w <- newWire
        return $ InputWire w
    expose (InputWire w) = InputWire w

instance Bits a => Interface (Output a) where
    data Ifc d (Output a) = OutputWire (Wire a)
    newIfc = do
        w <- newWire
        return $ OutputWire w
    expose (OutputWire w) = OutputWire w


type Component ifc = forall a. Inner ifc -> Circuit a

make :: Interface ifc => Component ifc -> Circuit (Outer ifc)
make compF = do
    ifc <- newIfc
    compF ifc
    return $ expose ifc


instance (Interface a, Interface b) => Interface (a,b) where
    data Ifc d (a,b) = TupleIfc (Ifc d a) (Ifc d b)
    newIfc = do
        x <- newIfc
        y <- newIfc
        return $ TupleIfc x y
    expose (TupleIfc x y) = TupleIfc (expose x) (expose y)
