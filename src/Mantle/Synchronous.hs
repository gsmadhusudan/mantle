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

newtype Clock = Clock (Wire Bool)

instance Readable Clock Bool where
    read (Clock w) = read w

newtype Reset = Reset (Wire Bool)

instance Readable Reset Bool where
    read (Reset w) = read w

type ClockReset = (Clock,Reset)

type Synchronous = ReaderT ClockReset Circuit

type SyncComp ifc = Inner ifc -> Synchronous ()

instance MonadCircuit Synchronous where
    liftCircuit = lift

makeSync :: Interface ifc =>
    ClockReset -> SyncComp ifc -> Circuit (Outer ifc)
makeSync cr syncF = (`runReaderT` cr) $ do
    ifc <- newIfc
    syncF ifc
    return $ expose ifc

syncTrigger :: Clock -> Reset -> Trigger
syncTrigger (Clock c) (Reset r) =
    posedge c <> negedge r

onSync :: Statement -> Synchronous ()
onSync stmt = do
    (clk,rst) <- ask
    onTrigger (syncTrigger clk rst) $ iff clk stmt

onReset :: Statement -> Synchronous ()
onReset stmt = do
    (clk,rst) <- ask
    onTrigger (syncTrigger clk rst) $ iff (not rst) stmt

(=~) :: (Writable w a, Readable r a) => w -> r -> Synchronous ()
w =~ e = onSync (w <=: e)

reg :: Bits a => Constant a -> Synchronous (Reg a)
reg x = do
    r <- newReg
    onReset (r <=: x)
    return r

