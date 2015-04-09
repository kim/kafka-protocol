{-# LANGUAGE ExistentialQuantification, OverloadedStrings #-}

module Network.Kafka.Internal
    ( checksum
    )
where

import Data.Bits
import Data.ByteString.Lazy as Lazy
import Data.ByteString.Lazy.Char8 ()
import Data.Vector.Unboxed as Unboxed
import Data.Word


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


checksum :: Lazy.ByteString -> Word32
checksum = runL crc32
