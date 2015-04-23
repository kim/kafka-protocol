{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE TypeFamilies    #-}

module Network.Kafka.Protocol.Primitive
    ( Bytes       (..)
    , ShortString (fromShortString)
    , Array       (..)
    , ErrorCode   (..)
    , sstr
    , unsafeSStr
    )
where

import           Control.Applicative
import           Data.ByteString     (ByteString)
import qualified Data.ByteString     as BS
import           Data.Int
import           Data.Maybe          (fromMaybe)
import           Data.Serialize
import           Data.Text           (Text)
import qualified Data.Text           as T
import           Data.Text.Encoding
import           Data.Vector         (Vector)
import qualified Data.Vector         as V
import           GHC.Exts


newtype Bytes = Bytes { fromBytes :: ByteString }
    deriving (Eq, Show)

instance Serialize Bytes where
    put (Bytes bs)
      | BS.length bs < 1 = put ((-1) :: Int32)
      | otherwise        = do
          put (fromIntegral (BS.length bs) :: Int32)
          put bs

    get = do
        len <- fromIntegral <$> (get :: Get Int32)
        if len < 1
          then return $ Bytes BS.empty
          else Bytes <$> getBytes len


newtype ShortString = ShortString { fromShortString :: Text }
    deriving (Eq, Show)

instance Serialize ShortString where
    put (ShortString t)
      | T.length t < 1 = put ((-1) :: Int32)
      | otherwise      = do
          put (fromIntegral (T.length t) :: Int16)
          put (encodeUtf8 t)

    get = do
        len <- fromIntegral <$> (get :: Get Int16)
        if len < 1
          then return $ ShortString T.empty
          else (ShortString . decodeUtf8) <$> getBytes len

sstr :: Text -> Maybe ShortString
sstr t
    | T.length t > fromIntegral (maxBound :: Int16) = Nothing
    | otherwise                                     = Just (ShortString t)

unsafeSStr :: Text -> ShortString
unsafeSStr = fromMaybe (error "Max string length exceeded") . sstr

instance IsString ShortString where
    fromString = unsafeSStr . T.pack

newtype Array a = Array { fromArray :: Vector a }
    deriving (Eq, Show)

instance IsList (Array a) where
    type Item (Array a) = a
    fromList = Array . fromList
    toList   = toList . fromArray

instance Serialize a => Serialize (Array a) where
    put (Array a) = do
        put (fromIntegral (V.length a) :: Int32)
        put (V.toList a)

    get = do
        n <- fromIntegral <$> (get :: Get Int32)
        (Array . V.take n . V.fromList) <$> get


data ErrorCode
    = NoError
    | OffsetOutOfRange
    | InvalidMessage
    | UnknownTopicOrPartition
    | InvalidMessageSize
    | LeaderNotAvailable
    | NotLeaderForPartition
    | RequestTimedOut
    | BrokerNotAvailable
    | ReplicaNotAvailable
    | MessageSizeTooLarge
    | StaleControllerEpoch
    | OffsetMetadataTooLarge
    | OffsetsLoadInProgress
    | ConsumerCoordinatorNotAvailable
    | NotCoordinatorForConsumer
    deriving (Eq, Show)

instance Serialize ErrorCode where
    put e = put $ case e of
        NoError                         -> 0   :: Int16
        OffsetOutOfRange                -> 1
        InvalidMessage                  -> 2
        UnknownTopicOrPartition         -> 3
        InvalidMessageSize              -> 4
        LeaderNotAvailable              -> 5
        NotLeaderForPartition           -> 6
        RequestTimedOut                 -> 7
        BrokerNotAvailable              -> 8
        ReplicaNotAvailable             -> 9
        MessageSizeTooLarge             -> 10
        StaleControllerEpoch            -> 11
        OffsetMetadataTooLarge          -> 12
        OffsetsLoadInProgress           -> 14
        ConsumerCoordinatorNotAvailable -> 15
        NotCoordinatorForConsumer       -> 16

    get = (get :: Get Int16) >>= \code -> case code of
        0  -> return NoError
        1  -> return OffsetOutOfRange
        2  -> return InvalidMessage
        3  -> return UnknownTopicOrPartition
        4  -> return InvalidMessageSize
        5  -> return LeaderNotAvailable
        6  -> return NotLeaderForPartition
        7  -> return RequestTimedOut
        8  -> return BrokerNotAvailable
        9  -> return ReplicaNotAvailable
        10 -> return MessageSizeTooLarge
        11 -> return StaleControllerEpoch
        12 -> return OffsetMetadataTooLarge
        14 -> return OffsetsLoadInProgress
        15 -> return ConsumerCoordinatorNotAvailable
        16 -> return NotCoordinatorForConsumer

        _  -> fail "Unkown error code"
