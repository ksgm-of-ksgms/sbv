-----------------------------------------------------------------------------
-- |
-- Module      :  TestSuite.Arrays.Memory
-- Copyright   :  (c) Levent Erkok
-- License     :  BSD3
-- Maintainer  :  erkokl@gmail.com
-- Stability   :  experimental
--
-- Test suite for Examples.Arrays.Memory
-----------------------------------------------------------------------------

{-# LANGUAGE Rank2Types #-}

module TestSuite.Arrays.Memory(tests) where

import Utils.SBVTestFramework

type AddressBase = Word32
type ValueBase   = Word64
type Address     = SBV AddressBase
type Value       = SBV ValueBase
type Memory m    = m AddressBase ValueBase

-- | read-after-write: If you write a value and read it back, you'll get it
raw :: SymArray m => Address -> Value -> Memory m -> SBool
raw a v m = readArray (writeArray m a v) a .== v

-- | if read from a place you didn't write to, the result doesn't change
rawd :: SymArray m => Address -> Address -> Value -> Memory m -> SBool
rawd a b v m = a ./= b ==> readArray (writeArray m a v) b .== readArray m b

-- | write-after-write: If you write to the same location twice, then the first one is ignored
waw :: SymArray m => Address -> Value -> Value -> Memory m -> Address -> SBool
waw a v1 v2 m0 i = readArray m2 i .== readArray m3 i
  where m1 = writeArray m0 a v1
        m2 = writeArray m1 a v2
        m3 = writeArray m0 a v2

-- | Two writes to different locations commute, i.e., can be done in any order
wcommutesGood :: SymArray m => (Address, Value) -> (Address, Value) -> Memory m -> Address -> SBool
wcommutesGood (a, x) (b, y) m i = a ./= b ==> wcommutesBad (a, x) (b, y) m i

-- | Two writes do not commute if they can be done to the same location
wcommutesBad :: SymArray m => (Address, Value) -> (Address, Value) -> Memory m -> Address -> SBool
wcommutesBad (a, x) (b, y) m i = readArray m0 i .== readArray m1 i
   where m0 = writeArray (writeArray m a x) b y
         m1 = writeArray (writeArray m b y) a x

-- | Extensionality. Note that we can only check this for SArray, since an SFunArray doesn't allow for
-- symbolic equality. (In other words, checking this for SFunArray would be saying "if all reads are the
-- same, then all reads are the same," which is useless at best.) Essentially, we need a nested
-- quantifier here.
extensionality :: Memory SArray -> Memory SArray -> Predicate
extensionality m1 m2 = do i <- exists_
                          return $ (readArray m1 i ./= readArray m2 i) ||| m1 .== m2

-- | Extensionality, second variant. Expressible for both kinds of arrays.
extensionality2 :: SymArray m => Memory m -> Memory m -> Address -> Predicate
extensionality2 m1 m2 i = do j <- exists_
                             return $ (readArray m1 j ./= readArray m2 j) ||| readArray m1 i .== readArray m2 i

tests :: TestTree
tests =
  testGroup "Arrays.Memory"
    [ testCase "raw_SArray"              $ assertIsThm   (raw :: Address -> Value -> Memory SArray    -> SBool)
    , testCase "raw_SFunArray"           $ assertIsThm   (raw :: Address -> Value -> Memory SFunArray -> SBool)

    , testCase "rawd_SArray"             $ assertIsThm   (rawd :: Address -> Address -> Value -> Memory SArray    -> SBool)
    , testCase "rawd_SFunArray"          $ assertIsThm   (rawd :: Address -> Address -> Value -> Memory SFunArray -> SBool)

    , testCase "waw_SArray"              $ assertIsThm   (waw :: Address -> Value -> Value -> Memory SArray    -> Address -> SBool)
    , testCase "waw_SFunArray"           $ assertIsThm   (waw :: Address -> Value -> Value -> Memory SFunArray -> Address -> SBool)

    , testCase "wcommute-good_SArray"    $ assertIsThm   (wcommutesGood :: (Address, Value) -> (Address, Value) -> Memory SArray    -> Address -> SBool)
    , testCase "wcommute-good_SFunArray" $ assertIsThm   (wcommutesGood :: (Address, Value) -> (Address, Value) -> Memory SFunArray -> Address -> SBool)

    , testCase "wcommute-bad_SArray"     $ assertIsntThm (wcommutesBad  :: (Address, Value) -> (Address, Value) -> Memory SArray    -> Address -> SBool)
    , testCase "wcommute-bad_SFunArray"  $ assertIsntThm (wcommutesBad  :: (Address, Value) -> (Address, Value) -> Memory SFunArray -> Address -> SBool)

    , testCase "ext_SArray"              $ assertIsThm   (extensionality :: Memory SArray -> Memory SArray -> Predicate)

    , testCase "ext2_SArray"             $ assertIsThm   (extensionality2 :: Memory SArray    -> Memory SArray    -> Address -> Predicate)
    , testCase "ext2_SFunArray"          $ assertIsThm   (extensionality2 :: Memory SFunArray -> Memory SFunArray -> Address -> Predicate)
    ]