-----------------------------------------------------------------------------
-- |
-- Module      :  TestSuite.CRC.CCITT
-- Copyright   :  (c) Levent Erkok
-- License     :  BSD3
-- Maintainer  :  erkokl@gmail.com
-- Stability   :  experimental
--
-- Test suite for Examples.CRC.CCITT
-----------------------------------------------------------------------------

module TestSuite.CRC.CCITT(testSuite) where

import Data.SBV

import Examples.CRC.CCITT
import SBVTest

-- Test suite
testSuite :: SBVTestSuite
testSuite = mkTestSuite $ \goldCheck -> test [
  "ccitt" ~: crcPgm `goldCheck` "ccitt.gold"
 ]
 where crcPgm = runSAT $ forAll_ crcGood >>= output
