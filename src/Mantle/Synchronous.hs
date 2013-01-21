{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Mantle.Synchronous where

import Mantle.Prelude

import Control.Monad.Reader
import qualified Data.Map as M
import qualified Data.Sequence as S
import qualified Data.Set as Set
import Data.Bits
import Data.Monoid

import Mantle.RTL
import Mantle.Circuit
import Mantle.Logic
import Mantle.Interface

newtype Clock = Clock { unClock :: ExtInput Bool }

newClock :: MonadCircuit c => c Clock
newClock = do
    c <- newExtInput
    return $ Clock c

newtype Reset = Reset { unReset :: ExtInput Bool }

newReset :: MonadCircuit c => c Reset
newReset = do
    r <- newExtInput
    return $ Reset r

type ClockReset = (Clock, Reset)

type Synchronous = ReaderT ClockReset Circuit

type SyncComp ifc = FlipIfc ifc -> Synchronous ()

instance MonadCircuit Synchronous where
    liftCircuit = lift

makeSync :: (Interface ifc, MonadCircuit c) =>
    ClockReset ->
    (FlipIfc ifc -> Synchronous ()) ->
    (FlipIfc ifc -> Circuit ())
makeSync cr syncF ifc = runReaderT (syncF ifc) cr

syncTrigger :: ClockReset -> Trigger
syncTrigger (Clock (ExtInput c), Reset (ExtInput r)) =
    posedge c <> negedge r

onSync :: Statement -> Synchronous ()
onSync stmt = do
    cr@(Clock (ExtInput c), _) <- ask
    onTrigger (syncTrigger cr) $ iff (Output (Var c)) stmt

onReset :: Statement -> Synchronous ()
onReset stmt = do
    cr@(_ ,(Reset (ExtInput r))) <- ask
    onTrigger (syncTrigger cr) $ iff (not (Output (Var r))) stmt

(=~) :: Reg a -> Output a -> Synchronous ()
w =~ e = onSync (w <=: e)

reg :: Bits a => a -> Synchronous (Reg a)
reg x = do
    r <- newReg
    onReset (r <=: literal x)
    return r

