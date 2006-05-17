-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Array.Parallel.Distributed.DistST
-- Copyright   :  (c) 2006 Roman Leshchinskiy
-- License     :  see libraries/base/LICENSE
-- 
-- Maintainer  :  Roman Leshchinskiy <rl@cse.unsw.edu.au>
-- Stability   :  experimental
-- Portability :  non-portable (GHC Extensions)
--
-- Distributed ST computations.
--
-- Computations of type 'DistST' are data-parallel computations which
-- are run on each thread of a gang. At the moment, they can only access the
-- element of a (possibly mutable) distributed value owned by the current
-- thread.
--
-- /TODO:/ Add facilities for implementing parallel scans etc.
--

module Data.Array.Parallel.Distributed.DistST (
  DistST, stToDistST, distST_, distST, runDistST,

  myD, readMyMD, writeMyMD
) where

import Data.Array.Parallel.Base (
  ST, runST)
import Data.Array.Parallel.Distributed.Gang
import Data.Array.Parallel.Distributed.Types (
  DT(..), Dist, MDist)

import Monad (liftM)

-- | Data-parallel computations.
newtype DistST s a = DistST { unDistST :: Int -> ST s a }

instance Monad (DistST s) where
  return         = DistST . const . return 
  DistST p >>= f = DistST $ \i -> do
                                    x <- p i
                                    unDistST (f x) i

-- | Yields the index of the current thread within its gang.
myIndex :: DistST s Int
myIndex = DistST return

-- | Lifts an 'ST' computation into the 'DistST' monad. The lifted computation
-- should be data parallel.
stToDistST :: ST s a -> DistST s a
stToDistST p = DistST $ \i -> p

-- | Yields the 'Dist' element owned by the current thread.
myD :: DT a => Dist a -> DistST s a
myD dt = liftM (indexD dt) myIndex

-- | Yields the 'MDist' element owned by the current thread.
readMyMD :: DT a => MDist a s -> DistST s a
readMyMD mdt = do
                 i <- myIndex
                 stToDistST $ readMD mdt i

-- | Writes the 'MDist' element owned by the current thread.
writeMyMD :: DT a => MDist a s -> a -> DistST s ()
writeMyMD mdt x = do
                    i <- myIndex
                    stToDistST $ writeMD mdt i x

-- | Execute a data-parallel computation on a 'Gang'.
distST_ :: Gang -> DistST s () -> ST s ()
distST_ g = gangST g . unDistST

-- | Execute a data-parallel computation, yielding the distributed result.
distST :: DT a => Gang -> DistST s a -> ST s (Dist a)
distST g p = do
               md <- newMD g
               distST_ g $ writeMyMD md =<< p
               unsafeFreezeMD md

-- | Run a data-parallel computation, yielding the distributed result.
runDistST :: DT a => Gang -> (forall s. DistST s a) -> Dist a
runDistST g p = runST (distST g p)
