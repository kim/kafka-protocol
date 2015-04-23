-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE OverloadedStrings         #-}
{-# LANGUAGE TypeFamilies              #-}


module Network.Kafka.Protocol.Internal
    ( fields
    , checksum
    )
where

import Control.Lens
import Data.Bits
import Data.ByteString.Lazy       as Lazy
import Data.ByteString.Lazy.Char8 ()
import Data.Vector.Unboxed        as Unboxed
import Data.Vinyl
import Data.Word


-- | Access the fields of any RPC message
fields :: (Wrapped w, Unwrapped w ~ FieldRec f) => w -> FieldRec f
fields = op undefined

-- | Calculate the crc32 checksum of a 'Lazy.ByteString'
checksum :: Lazy.ByteString -> Word32
checksum = runL crc32

--
-- crc32 acc. to ekmett
--

data L b a = forall x. L (x -> b -> x) x (x -> a)

runL :: L Word8 a -> Lazy.ByteString -> a
runL (L xbx x xa) bs = xa (Lazy.foldl' xbx x bs)

crc32 :: L Word8 Word32
crc32 = L step 0xffffffff complement where
  step r b = unsafeShiftR r 8
       `xor` crcs Unboxed.! fromIntegral (xor r (fromIntegral b) .&. 0xff)

crcs :: Unboxed.Vector Word32
crcs = Unboxed.generate 256 (go.go.go.go.go.go.go.go.fromIntegral)
  where
    go c = unsafeShiftR c 1 `xor` if c .&. 1 /= 0 then 0xedb88320 else 0
