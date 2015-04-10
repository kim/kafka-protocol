-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE GADTs               #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving  #-}


-- | Implementation of the <http://kafka.apache.org Kafka> wire protocol
--
-- cf. <https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol>
--
module Network.Kafka.Protocol
    ( -- * \"Primitive\" types
      Bytes                         (..)
    , ShortString                   (..)
    , Array                         (..)

    -- * Wrappers
    , Request                       ( rq_apiKey
                                    , rq_apiVersion
                                    , rq_correlationId
                                    , rq_clientId
                                    , rq_request
                                    )
    , mkRequest
    , Response                      (..)
    , ApiKey                        (..)
    , apiKey
    , ApiVersion                    (..)
    , apiVersion

    -- * Messages
    , Compression                   (..)
    , MessageSet                    (..)
    , Message                       ( msg_crc
                                    , msg_magic
                                    , msg_attrs
                                    , msg_key
                                    , msg_value
                                    )
    , mkMessage

    -- * Error codes
    , ErrorCode                     (..)

    -- * Type aliases
    , ConsumerGroup
    , Host
    , MessageSetSize
    , NodeId
    , Offset
    , Partition
    , Port
    , TopicKeyed
    , TopicName

    -- * RPCs
    , FetchRequest                  (..)
    , FetchResponse                 (..)
    , FetchResponsePayload          (..)

    , ProduceRequest                (..)
    , ProduceRequestPayload         (..)
    , ProduceResponse               (..)
    , ProduceResponsePayload        (..)

    , OffsetRequest                 (..)
    , OffsetRequestPayload          (..)
    , OffsetResponse                (..)
    , OffsetResponsePayload         (..)

    , OffsetCommitRequest           (..)
    , OffsetCommitRequestPayload    (..)
    , OffsetCommitResponse          (..)
    , OffsetCommitResponsePayload   (..)

    , OffsetFetchRequest            (..)
    , OffsetFetchResponse           (..)
    , OffsetFetchResponsePayload    (..)

    -- ** Metadata
    , Broker                        (..)
    , MetadataRequest               (..)
    , MetadataResponse              (..)
    , ConsumerMetadataRequest       (..)
    , ConsumerMetadataResponse      (..)
    , TopicMetadata                 (..)
    , PartitionMetadata             (..)

    -- ** Consumer coordination
    , HeartbeatRequest              (..)
    , HeartbeatResponse             (..)
    , JoinGroupRequest              (..)
    , JoinGroupResponse             (..)
    )
where


import           Control.Applicative
import           Data.Bits
import           Data.ByteString        (ByteString)
import qualified Data.ByteString        as BS
import           Data.Int
import           Data.Maybe
import           Data.Proxy
import           Data.Serialize
import           Data.Text              (Text)
import qualified Data.Text              as T
import           Data.Text.Encoding
import           Data.Vector            (Vector)
import qualified Data.Vector            as V
import           GHC.Generics
import           GHC.TypeLits
import           Network.Kafka.Internal


--
-- primitives
--

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

-- todo: type-level constrain to length <= maxBound :: Int16
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

newtype Array a = Array { fromArray :: Vector a }
    deriving (Eq, Show)

instance Serialize a => Serialize (Array a) where
    put (Array a) = do
        put (fromIntegral (V.length a) :: Int32)
        put (V.toList a)

    get = do
        n <- fromIntegral <$> (get :: Get Int32)
        (Array . V.take n . V.fromList) <$> get

--
-- wrappers
--

data Request a = Request
    { rq_apiKey        :: !ApiKey
    , rq_apiVersion    :: !ApiVersion
    , rq_correlationId :: !Int32
    , rq_clientId      :: !ShortString
    , rq_request       :: !a
    } deriving (Eq, Show)

instance Serialize a => Serialize (Request a) where
    put rq = do
        put (fromIntegral (BS.length rq') :: Int32)
        put rq'
      where
        rq' = runPut (put rq)

    get = do
        len <- get :: Get Int32
        bs  <- getBytes (fromIntegral len)
        either fail return $ runGet get' bs
      where
        get' = Request <$> get <*> get <*> get <*> get <*> get

mkRequest :: (KnownNat key, KnownNat version)
          => Int32
          -> ShortString
          -> a key version
          -> Request (a key version)
mkRequest correlationId clientId rq = Request
    { rq_apiKey        = apiKey rq
    , rq_apiVersion    = apiVersion rq
    , rq_correlationId = correlationId
    , rq_clientId      = clientId
    , rq_request       = rq
    }


data Response a = Response
    { rs_correlationId :: !Int32
    , rs_response      :: !a
    } deriving (Eq, Show)

instance Serialize a => Serialize (Response a) where
    put rs = do
        put (fromIntegral (BS.length rs') :: Int32)
        put rs'
      where
        rs' = runPut (put rs)

    get = do
        len <- get :: Get Int32
        bs  <- getBytes (fromIntegral len)
        either fail return $ runGet get' bs
      where
        get' = Response <$> get <*> get


newtype ApiKey = ApiKey Int16
    deriving (Eq, Show, Generic)

instance Serialize ApiKey

apiKey :: forall a key version. (KnownNat key, KnownNat version)
       => a key version
       -> ApiKey
apiKey _ = ApiKey . fromInteger $ natVal (Proxy :: Proxy key)


newtype ApiVersion = ApiVersion Int16
    deriving (Eq, Show, Generic)

instance Serialize ApiVersion

apiVersion :: forall a key version. (KnownNat key, KnownNat version)
            => a key version
            -> ApiVersion
apiVersion _ = ApiVersion . fromInteger $ natVal (Proxy :: Proxy version)


--
-- messages
--

data Compression = Uncompressed | GZIP | Snappy | LZ4
    deriving (Eq, Show)

newtype MessageSet = MessageSet ([(Offset, Int32, Message)])
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


--
-- error codes
--

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


--
-- RPCs
--

type TopicName      = ShortString
type Partition      = Int32
type MessageSetSize = Int32
type ConsumerGroup  = ShortString
type Offset         = Int64
type NodeId         = Int32
type Host           = ShortString
type Port           = Int32


type TopicKeyed a = Array (TopicName, Array a)


--
-- Produce
--
data ProduceRequest (key :: Nat) (version :: Nat) where
    ProduceRequest :: { prq_requiredAcks :: !Int16
                      , prq_timeout      :: !Int32
                      , prq_payload      :: !(TopicKeyed ProduceRequestPayload)
                      }
                   -> ProduceRequest 1 0

deriving instance Eq   (ProduceRequest k v)
deriving instance Show (ProduceRequest k v)

data ProduceRequestPayload = ProduceRequestPayload
    { prqp_partition :: !Partition
    , prqp_size      :: !MessageSetSize
    , prqp_messages  :: !MessageSet
    } deriving (Eq, Show, Generic)

newtype ProduceResponse = ProduceResponse (TopicKeyed ProduceResponsePayload)
    deriving (Eq, Show, Generic)

data ProduceResponsePayload = ProduceResponsePayload
    { prsp_partition :: !Partition
    , prsp_errorCode :: !ErrorCode
    , prsp_offset    :: !Offset
    } deriving (Eq, Show, Generic)

instance Serialize (ProduceRequest 1 0) where
    put (ProduceRequest r t p) = put r *> put t *> put p
    get = ProduceRequest <$> get <*> get <*> get

instance Serialize ProduceRequestPayload
instance Serialize ProduceResponse
instance Serialize ProduceResponsePayload


--
-- Fetch
--
data FetchRequest (key :: Nat) (version :: Nat) where
    FetchRequest :: { frq_replicaId   :: !NodeId
                    , frq_maxWaitTime :: !Int32
                    , frq_minBytes    :: !Int32
                    , frq_topic       :: !TopicName
                    , frq_partition   :: !Partition
                    , frq_offset      :: !Int64
                    , frq_maxBytes    :: !Int32
                    }
                 -> FetchRequest 1 0

deriving instance Eq   (FetchRequest k v)
deriving instance Show (FetchRequest k v)

newtype FetchResponse = FetchResponse (TopicKeyed FetchResponsePayload)
    deriving (Eq, Show, Generic)

data FetchResponsePayload = FetchResponsePayload
    { frsp_partition      :: !Partition
    , frsp_errorCode      :: !ErrorCode
    , frsp_offset         :: !Offset
    , frsp_messageSetSize :: !Int32
    , frsp_messageSet     :: !MessageSet
    } deriving (Eq, Show, Generic)

instance Serialize (FetchRequest 1 0) where
    put (FetchRequest r x minb t p o maxb) = put r *> put x *> put minb *> put t *> put p *> put o *> put maxb
    get = FetchRequest <$> get <*> get <*> get <*> get <*> get <*> get <*> get

instance Serialize FetchResponse
instance Serialize FetchResponsePayload


--
-- Offset
--
data OffsetRequest (key :: Nat) (version :: Nat) where
    OffsetRequest :: { orq_replicaId :: !NodeId
                     , orq_payload   :: !(TopicKeyed OffsetRequestPayload)
                     }
                  -> OffsetRequest 2 0

deriving instance Eq   (OffsetRequest k v)
deriving instance Show (OffsetRequest k v)

data OffsetRequestPayload = OffsetRequestPayload
    { orqp_partition  :: !Partition
    , orqp_time       :: !Int64
    , orqp_maxOffsets :: !Int32
    } deriving (Eq, Show, Generic)

newtype OffsetResponse = OffsetResponse (TopicKeyed OffsetResponsePayload)
    deriving (Eq, Show, Generic)

data OffsetResponsePayload = OffsetResponsePayload
    { orsp_partition :: !Partition
    , orsp_errorCode :: !ErrorCode
    , orsp_offsets   :: !(Array Offset)
    } deriving (Eq, Show, Generic)

instance Serialize (OffsetRequest 2 0) where
    put (OffsetRequest r p) = put r *> put p
    get = OffsetRequest <$> get <*> get

instance Serialize OffsetRequestPayload
instance Serialize OffsetResponse
instance Serialize OffsetResponsePayload


--
-- Metadata
--
data MetadataRequest (key :: Nat) (version :: Nat) where
    MetadataRequest :: { mrq_topics :: !(Array TopicName) }
                    -> MetadataRequest 3 0

deriving instance Eq   (MetadataRequest k v)
deriving instance Show (MetadataRequest k v)

data MetadataResponse = MetadataResponse !(Array Broker) !(Array TopicMetadata)
    deriving (Eq, Show, Generic)

data Broker = Broker !NodeId !Host !Port
    deriving (Eq, Show, Generic)

data TopicMetadata = TopicMetadata
    { topic_errorCode     :: !ErrorCode
    , topic_topic         :: !TopicName
    , topic_partitionMeta :: !(Array PartitionMetadata)
    } deriving (Eq, Show, Generic)

data PartitionMetadata = PartitionMetadata
    { part_errorCode   :: !ErrorCode
    , part_partitionId :: !Partition
    , part_leader      :: !NodeId
    , part_replicas    :: !(Array NodeId)
    , part_isr         :: !(Array NodeId)
    } deriving (Eq, Show, Generic)

instance Serialize (MetadataRequest 3 0) where
    put (MetadataRequest ts) = put ts
    get = MetadataRequest <$> get

instance Serialize MetadataResponse
instance Serialize Broker
instance Serialize TopicMetadata
instance Serialize PartitionMetadata


--
-- OffsetCommit
--
data OffsetCommitRequest (key :: Nat) (version :: Nat) where
    OffsetCommitRequest'V0 :: { ocrq0_consumerGroup :: !ConsumerGroup
                              , ocrq0_payload       :: !(TopicKeyed (OffsetCommitRequestPayload 0))
                              }
                           -> OffsetCommitRequest 8 0

    OffsetCommitRequest'V1 :: { ocrq1_consumerGroup :: !ConsumerGroup
                              , ocrq1_generation    :: !Int32
                              , ocrq1_consumerId    :: !ShortString
                              , ocrq1_payload       :: !(TopicKeyed (OffsetCommitRequestPayload 1))
                              }
                           -> OffsetCommitRequest 8 1

    OffsetCommitRequest'V2 :: { ocrq2_consumerGroup :: !ConsumerGroup
                              , ocrq2_generation    :: !Int32
                              , ocrq2_retention     :: !Int64
                              , ocrq2_payload       :: !(TopicKeyed (OffsetCommitRequestPayload 0))
                              }
                           -> OffsetCommitRequest 8 2

deriving instance Eq   (OffsetCommitRequest k v)
deriving instance Show (OffsetCommitRequest k v)

data OffsetCommitRequestPayload (version :: Nat) where
    OffsetCommitRequestPayload'V0 :: { ocrqp_partition :: !Partition
                                     , ocrqp_offset    :: !Offset
                                     , ocrqp_metadata  :: !ShortString
                                     }
                                  -> OffsetCommitRequestPayload 0

    OffsetCommitRequestPayload'V1 :: { ocrqp1_partition :: !Partition
                                     , ocrqp1_offset    :: !Offset
                                     , ocrqp1_timestamp :: !Int64
                                     , ocrqp1_metadata  :: !ShortString
                                     }
                                  -> OffsetCommitRequestPayload 1

deriving instance Eq   (OffsetCommitRequestPayload v)
deriving instance Show (OffsetCommitRequestPayload v)

newtype OffsetCommitResponse = OffsetCommitResponse (TopicKeyed OffsetCommitResponsePayload)
    deriving (Eq, Show, Generic)

data OffsetCommitResponsePayload = OffsetCommitResponsePayload
    { ocrsp_partition :: !Partition
    , ocrsp_errorCode :: !ErrorCode
    } deriving (Eq, Show, Generic)

instance Serialize (OffsetCommitRequest 8 0) where
    put (OffsetCommitRequest'V0 c p) = put c *> put p
    get = OffsetCommitRequest'V0 <$> get <*> get

instance Serialize (OffsetCommitRequest 8 1) where
    put (OffsetCommitRequest'V1 cg g c p) = put cg *> put g *> put c *> put p
    get = OffsetCommitRequest'V1 <$> get <*> get <*> get <*> get

instance Serialize (OffsetCommitRequest 8 2) where
    put (OffsetCommitRequest'V2 cg g r p) = put cg *> put g *> put r *> put p
    get = OffsetCommitRequest'V2 <$> get <*> get <*> get <*> get

instance Serialize (OffsetCommitRequestPayload 0) where
    put (OffsetCommitRequestPayload'V0 p o m) = put p *> put o *> put m
    get = OffsetCommitRequestPayload'V0 <$> get <*> get <*> get

instance Serialize (OffsetCommitRequestPayload 1) where
    put (OffsetCommitRequestPayload'V1 p o t m) = put p *> put o *> put t *> put m
    get = OffsetCommitRequestPayload'V1 <$> get <*> get <*> get <*> get

instance Serialize OffsetCommitResponse
instance Serialize OffsetCommitResponsePayload


--
-- OffsetFetch
--

-- | Note that:
--
-- @
-- version 0 and 1 have exactly the same wire format, but different functionality.
-- version 0 will read the offsets from ZK and version 1 will read the offsets from Kafka.
-- @
--
-- (cf.  <https://github.com/apache/kafka/blob/0.8.2/core/src/main/scala/kafka/api/OffsetFetchRequest.scala>)
data OffsetFetchRequest (key :: Nat) (version :: Nat) where
    OffsetFetchRequest'V0 :: { ofrq_consumerGroup :: !ConsumerGroup
                             , ofrq_payload       :: !(TopicKeyed Partition)
                             }
                          -> OffsetFetchRequest 9 0

    OffsetFetchRequest'V1 :: { ofrq1_consumerGroup :: !ConsumerGroup
                             , ofrq1_payload       :: !(TopicKeyed Partition)
                             }
                          -> OffsetFetchRequest 9 1

deriving instance Eq   (OffsetFetchRequest k v)
deriving instance Show (OffsetFetchRequest k v)

newtype OffsetFetchResponse = OffsetFetchResponse (TopicKeyed OffsetFetchResponsePayload)
    deriving (Eq, Show, Generic)

data OffsetFetchResponsePayload = OffsetFetchResponsePayload
    { ofrsp_partition :: !Partition
    , ofrsp_offset    :: !Offset
    , ofrsp_metadata  :: !ShortString
    , ofrsp_errorCode :: !ErrorCode
    } deriving (Eq, Show, Generic)

instance Serialize (OffsetFetchRequest 9 0) where
    put (OffsetFetchRequest'V0 g p) = put g *> put p
    get = OffsetFetchRequest'V0 <$> get <*> get

instance Serialize (OffsetFetchRequest 9 1) where
    put (OffsetFetchRequest'V1 g p) = put g *> put p
    get = OffsetFetchRequest'V1 <$> get <*> get

instance Serialize OffsetFetchResponse
instance Serialize OffsetFetchResponsePayload


--
-- ConsumerMetadata
--
data ConsumerMetadataRequest (key :: Nat) (version :: Nat) where
    ConsumerMetadataRequest :: { cmrq_consumerGroup :: !ConsumerGroup }
                            -> ConsumerMetadataRequest 10 0

deriving instance Eq   (ConsumerMetadataRequest k v)
deriving instance Show (ConsumerMetadataRequest k v)

data ConsumerMetadataResponse = ConsumerMetadataResponse
    { cmrs_errorCode       :: !ErrorCode
    , cmrs_coordinatorId   :: !Int32
    , cmrs_coordinatorHost :: !Host
    , cmrs_coordinatorPort :: !Port
    } deriving (Eq, Show, Generic)

instance Serialize (ConsumerMetadataRequest 10 0) where
    put (ConsumerMetadataRequest g) = put g
    get = ConsumerMetadataRequest <$> get

instance Serialize ConsumerMetadataResponse

--
-- Heartbeat
--
data HeartbeatRequest (key :: Nat) (version :: Nat) where
    HeartbeatRequest :: { hrq_consumerGroup   :: !ConsumerGroup
                        , hrq_groupGeneration :: !Int32
                        , hrq_consumerId      :: !ShortString
                        }
                     -> HeartbeatRequest 12 0

deriving instance Eq   (HeartbeatRequest k v)
deriving instance Show (HeartbeatRequest k v)

newtype HeartbeatResponse = HeartbeatResponse ErrorCode
    deriving (Eq, Show, Generic)

instance Serialize (HeartbeatRequest 12 0) where
    put (HeartbeatRequest cg g c) = put cg *> put g *> put c
    get = HeartbeatRequest <$> get <*> get <*> get

instance Serialize HeartbeatResponse


--
-- JoinGroup
--
data JoinGroupRequest (key :: Nat) (version :: Nat) where
    JoinGroupRequest :: { jgrq_consumerGroup               :: !ConsumerGroup
                        , jgrq_sessionTimeout              :: !Int32
                        , jgrq_topics                      :: !(Array TopicName)
                        , jgrq_consumerId                  :: !ShortString
                        , jgrq_partitionAssignmentStrategy :: !ShortString
                        }
                     -> JoinGroupRequest 11 0

deriving instance Eq   (JoinGroupRequest k v)
deriving instance Show (JoinGroupRequest k v)

data JoinGroupResponse = JoinGroupResponse
    { jgrs_errorCode          :: !ErrorCode
    , jgrs_groupGeneration    :: !Int32
    , jgrs_consumerId         :: !ShortString
    , jgrs_assignedPartitions :: !(TopicKeyed Partition)
    } deriving (Eq, Show, Generic)

instance Serialize (JoinGroupRequest 11 0) where
    put (JoinGroupRequest cg s t c p) = put cg *> put s *> put t *> put c *> put p
    get = JoinGroupRequest <$> get <*> get <*> get <*> get <*> get

instance Serialize JoinGroupResponse
