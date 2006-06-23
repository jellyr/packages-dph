-----------------------------------------------------------------------------
-- |
-- Module      : Data.Array.Parallel.Unlifted.Segmented.SUArr
-- Copyright   : (c) [2001..2002] Manuel M T Chakravarty & Gabriele Keller
--		 (c) 2006         Manuel M T Chakravarty & Roman Leshchinskiy
-- License     : see libraries/base/LICENSE
-- 
-- Maintainer  : Manuel M T Chakravarty <chak@cse.unsw.edu.au>
-- Stability   : internal
-- Portability : portable
--
-- Description ---------------------------------------------------------------
--
-- This module defines segmented arrays in terms of unsegmented ones.
--
-- Todo ----------------------------------------------------------------------
--

module Data.Array.Parallel.Unlifted.Segmented.SUArr (

  -- * Array types and classes containing the admissble elements types
  USegd(..), MUSegd(..), SUArr(..), MSUArr(..),

  -- * Basic operations on segmented parallel arrays
  lengthSU,
  flattenSU, (>:),
  newMSU, unsafeFreezeMSU,
  toUSegd, fromUSegd
) where

-- friends
import Data.Array.Parallel.Base (
  (:*:)(..), ST)
import Data.Array.Parallel.Unlifted.Flat (
  UA, UArr, MUArr,
  lengthU, (!:), scanU,
  newMU, unsafeFreezeMU)

infixr 9 >:


-- |Segmented arrays
-- -----------------

-- |Segment descriptors are used to represent the structure of nested arrays.
--
data USegd = USegd {
	       segdUS :: !(UArr Int),  -- segment lengths
	       psumUS :: !(UArr Int)   -- prefix sum of former
	     }

-- |Mutable segment descriptor
--
data MUSegd s = MUSegd {
	          segdMUS :: !(MUArr Int s),  -- segment lengths
	          psumMUS :: !(MUArr Int s)   -- prefix sum of former
	        }

-- |Segmented arrays (only one level of segmentation)
-- 
data SUArr e = SUArr {
                 segdSU :: !USegd,             -- segment descriptor
                 dataSU :: !(UArr e)           -- flat data array
               }

-- |Mutable segmented arrays (only one level of segmentation)
--
data MSUArr e s = MSUArr {
                    segdMSU :: !(MUSegd s),    -- segment descriptor
                    dataMSU :: !(MUArr e s)    -- flat data array
                  }

-- |Operations on segmented arrays
-- -------------------------------

-- |Yield the number of segments.
-- 
lengthSU :: UA e => SUArr e -> Int
lengthSU (SUArr segd _) = lengthU (segdUS segd)

-- |The functions `newMSU', `nextMSU', and `unsafeFreezeMSU' are to 
-- iteratively define a segmented mutable array; i.e., arrays of type `MSUArr
-- s e`.

-- |Allocate a segmented parallel array (providing the number of segments and
-- number of base elements).
--
newMSU :: UA e => Int -> Int -> ST s (MSUArr e s)
{-# INLINE newMSU #-}
newMSU nsegd n = do
		   segd <- newMU nsegd
		   psum <- newMU nsegd
		   a    <- newMU n
		   return $ MSUArr (MUSegd segd psum) a

-- |Convert a mutable segmented array into an immutable one.
--
unsafeFreezeMSU :: UA e => MSUArr e s -> Int -> ST s (SUArr e)
{-# INLINE unsafeFreezeMSU #-}
unsafeFreezeMSU (MSUArr segd a) n = 
  do
    segd' <- unsafeFreezeMU (segdMUS segd) n
    psum' <- unsafeFreezeMU (psumMUS segd) n
    let n' = if n == 0 then 0 else psum' !: (n - 1) + 
				   segd' !: (n - 1)
    a' <- unsafeFreezeMU a n'
    return $ SUArr (USegd segd' psum') a'


-- |Basic operations on segmented arrays
-- -------------------------------------

-- |Compose a nested array.
--
(>:) :: UA a => USegd -> UArr a -> SUArr a
{-# INLINE [1] (>:) #-}  -- see `UAFusion'
(>:) = SUArr

-- |Decompose a nested array.
--
flattenSU :: UA a => SUArr a -> (USegd :*: UArr a)
flattenSU (SUArr segd a) = (segd :*: a)

-- |Convert a length array into a segment descriptor.
--
toUSegd :: UArr Int -> USegd 
toUSegd lens = USegd lens (scanU (+) 0 lens)

-- |Extract the length array from a segment descriptor.
--
fromUSegd :: USegd -> UArr Int
fromUSegd (USegd lens _) = lens

