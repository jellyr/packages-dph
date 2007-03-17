-----------------------------------------------------------------------------
-- |
-- Module      : Data.Array.Parallel.Unlifted.Parallel.Combinators
-- Copyright   : (c) 2006         Roman Leshchinskiy
-- License     : see libraries/ndp/LICENSE
-- 
-- Maintainer  : Roman Leshchinskiy <rl@cse.unsw.edu.au>
-- Stability   : experimental
-- Portability : portable
--
-- Description ---------------------------------------------------------------
--
-- Parallel combinators for unlifted arrays
--

module Data.Array.Parallel.Unlifted.Parallel.Combinators (
  mapUP, filterUP, zipWithUP, foldUP
) where

import Data.Array.Parallel.Base
import Data.Array.Parallel.Unlifted.Flat
import Data.Array.Parallel.Unlifted.Distributed

mapUP :: (UA a, UA b) => (a -> b) -> UArr a -> UArr b
{-# INLINE mapUP #-}
mapUP f = splitJoinD theGang (mapD theGang (mapU f))

filterUP :: UA a => (a -> Bool) -> UArr a -> UArr a
{-# INLINE filterUP #-}
filterUP f = joinD  theGang unbalanced
           . mapD   theGang (filterU f)
           . splitD theGang unbalanced

zipWithUP :: (UA a, UA b, UA c) => (a -> b -> c) -> UArr a -> UArr b -> UArr c
{-# INLINE zipWithUP #-}
zipWithUP f a b = joinD    theGang balanced
                $ zipWithD theGang (zipWithU f)
                    (splitD theGang balanced a)
                    (splitD theGang balanced b)
--zipWithUP f a b = mapUP (uncurryS f) (zipU a b)

foldUP :: (UA a, DT a) => (a -> a -> a) -> a -> UArr a -> a
{-# INLINE foldUP #-}
foldUP f z = maybeS z (f z)
           . foldD  theGang combine
           . mapD   theGang (foldl1MaybeU f)
           . splitD theGang unbalanced
  where
    combine (JustS x) (JustS y) = JustS (f x y)
    combine (JustS x) NothingS  = JustS x
    combine NothingS  (JustS y) = JustS y
    combine NothingS  NothingS  = NothingS

