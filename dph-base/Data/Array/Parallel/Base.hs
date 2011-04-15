-----------------------------------------------------------------------------
-- |
-- Module      : Data.Array.Parallel.Base
-- Copyright   : (c) [2006,2007]        Roman Leshchinsskiy
-- License     : see libraries/ndp/LICENSE
-- 
-- Maintainer  : Roman Leshchinskiy <rl@cse.unsw.edu.au>
-- Stability   : internal
-- Portability : non-portable (unboxed values and GHC libraries)
--
--
-- Interface to the Base modules
--

module Data.Array.Parallel.Base (
  module Data.Array.Parallel.Base.Debug,
  module Data.Array.Parallel.Base.Util,
  module Data.Array.Parallel.Base.Text,
  module Data.Array.Parallel.Base.DTrace,
  module Data.Array.Parallel.Base.TracePrim,
  ST(..), runST
) where

import Data.Array.Parallel.Base.Debug
import Data.Array.Parallel.Base.Util
import Data.Array.Parallel.Base.Text
import Data.Array.Parallel.Base.DTrace
import Data.Array.Parallel.Base.TracePrim

import GHC.ST (ST(..), runST)

