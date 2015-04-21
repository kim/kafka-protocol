{-# LANGUAGE DeriveGeneric #-}

module Network.Kafka.Protocol.Message
where

import           Data.Bits
import qualified Data.ByteString                  as BS
import           Data.Int
import           Data.Maybe                       (fromMaybe)
import           Data.Serialize
import           GHC.Generics
import           Network.Kafka.Internal
import           Network.Kafka.Protocol.Primitive


data Compression = Uncompressed | GZIP | Snappy | LZ4
    deriving (Eq, Show)

newtype MessageSet = MessageSet ([(Int64, Int32, Message)])
    deriving (Eq, Show, Generic)

instance Serialize MessageSet

data Message = Message
    { msg_crc   :: !Int32
    , msg_magic :: !Int8
    , msg_attrs :: !Int8 -- lower 2 bits store compression
    , msg_key   :: !Bytes
    , msg_value :: !Bytes
    } deriving (Eq, Show, Generic)

instance Serialize Message


mkMessage :: Maybe Bytes -> Bytes -> Compression -> Message
mkMessage key val codec =
    let magic = 0
        attrs = case codec of
            Uncompressed -> 0
            GZIP         -> 0 .|. (0x07 .&. 1)
            Snappy       -> 0 .|. (0x07 .&. 2)
            LZ4          -> 0 .|. (0x07 .&. 3)
        key'  = fromMaybe (Bytes BS.empty) key
        crc   = fromIntegral . checksum $ encodeLazy (magic, attrs, key', val)
     in Message crc magic attrs key' val
