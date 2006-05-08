-----------------------------------------------------------------------------
-- |
-- Module      :  Data.Array.Parallel.Distributed.Basics
-- Copyright   :  (c) 2006 Roman Leshchinskiy
-- License     :  see libraries/base/LICENSE
-- 
-- Maintainer  :  Roman Leshchinskiy <rl@cse.unsw.edu.au>
-- Stability   :  experimental
-- Portability :  non-portable (GHC Extensions)
--
-- Standard combinators for distributed types.
--

module Data.Array.Parallel.Distributed.Combinators (
  mapD, zipD, unzipD, fstD, sndD, zipWithD,
  foldD, scanD,

  -- * Monadic combinators
  mapDST_, mapDST, zipWithDST_, zipWithDST
) where

import Data.Array.Parallel.Base (
  (:*:)(..), uncurryS, ST, runST)
import Data.Array.Parallel.Distributed.Gang (
  Gang, gangSize)
import Data.Array.Parallel.Distributed.Types (
  DT, Dist, indexD, zipD, unzipD, fstD, sndD,
  newMD, writeMD, unsafeFreezeMD,
  checkGangD)
import Data.Array.Parallel.Distributed.DistST (
  DistST, distST_, distST, runDistST, myD)

here s = "Data.Array.Parallel.Distributed.Combinators." ++ s

-- | Map a function over a distributed value.
mapD :: (DT a, DT b) => Gang -> (a -> b) -> Dist a -> Dist b
mapD g f d = checkGangD (here "mapD") g d $
             runDistST g (myD d >>= return . f)

-- zipD, unzipD, fstD, sndD reexported from Types

-- | Combine two distributed values with the given function.
zipWithD :: (DT a, DT b, DT c)
         => Gang -> (a -> b -> c) -> Dist a -> Dist b -> Dist c
zipWithD g f dx dy = mapD g (uncurryS f) (zipD dx dy)

-- | Fold a distributed value.
foldD :: DT a => Gang -> (a -> a -> a) -> Dist a -> a
foldD g f d = checkGangD ("here foldD") g d $
              fold 1 (d `indexD` 0)
  where
    n = gangSize g
    --
    fold i x | i == n    = x
             | otherwise = fold (i+1) (f x $ d `indexD` i)

-- | Prefix sum of a distributed value.
scanD :: DT a => Gang -> (a -> a -> a) -> a -> Dist a -> Dist a :*: a
scanD g f z d = checkGangD (here "scanD") g d $
                runST (do
                  md <- newMD g
                  s  <- scan md 0 z
                  d' <- unsafeFreezeMD md
                  return (d' :*: s))
  where
    n = gangSize g
    --
    scan md i x | i == n    = return x
                | otherwise = do
                                writeMD md i x
                                scan md (i+1) (f x $ d `indexD` i)

mapDST_ :: DT a => Gang -> (a -> DistST s ()) -> Dist a -> ST s ()
mapDST_ g p d = checkGangD (here "mapDST_") g d $
                distST_ g (myD d >>= p)

mapDST :: (DT a, DT b) => Gang -> (a -> DistST s b) -> Dist a -> ST s (Dist b)
mapDST g p d = checkGangD (here "mapDST_") g d $
               distST g (myD d >>= p)

zipWithDST_ :: (DT a, DT b)
            => Gang -> (a -> b -> DistST s ()) -> Dist a -> Dist b -> ST s ()
zipWithDST_ g p dx dy = mapDST_ g (uncurryS p) (zipD dx dy)

zipWithDST :: (DT a, DT b, DT c)
           => Gang
           -> (a -> b -> DistST s c) -> Dist a -> Dist b -> ST s (Dist c)
zipWithDST g p dx dy = mapDST g (uncurryS p) (zipD dx dy)

