-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.


{-# LANGUAGE DeriveGeneric  #-}


-- | Implementation of the <http://kafka.apache.org Kafka> wire protocol (as of
-- version 0.8.2)
--
-- cf. <https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol>
--
module Network.Kafka.Protocol
    ( -- * "Primitive" types
      Bytes                         (..)
    , ShortString                   (..)
    , Array                         (..)

    -- * Wrappers
    , RequestMessage                (..)
    , ResponseMessage               (..)
    , ApiKey                        (..)

    -- * Messages
    , Compression                   (..)
    , MessageSet                    (..)
    , Message
    , mkMessage

    -- * Error codes
    , ErrorCode                     (..)

    -- * Type aliases
    , Partition
    , MessageSetSize
    , ConsumerGroup
    , Offset
    , TopicKeyed
    , NodeId
    , Host
    , Port

    -- * RPCs
    , Response                      (..)

    , FetchRequest                  (..)
    , FetchResponsePayload          (..)

    , ProduceRequest                (..)
    , ProduceRequestPayload         (..)
    , ProduceResponsePayload        (..)

    , OffsetRequest                 (..)
    , OffsetRequestPayload          (..)
    , OffsetResponsePayload         (..)

    , OffsetCommitRequest           (..)
    , OffsetCommitRequestPayload    (..)
    , OffsetCommitRequest_V1        (..)
    , OffsetCommitRequestPayload_V1 (..)
    , OffsetCommitRequest_V2        (..)
    , OffsetCommitResponsePayload   (..)

    , OffsetFetchRequest            (..)
    , OffsetFetchResponsePayload    (..)

    -- * Metadata
    , Broker                        (..)
    , MetadataRequest               (..)
    , ConsumerMetadataRequest       (..)
    , TopicMetadata                 (..)
    , PartitionMetadata             (..)

    -- * Consumer coordination
    , HeartbeatRequest              (..)
    , JoinGroupRequest              (..)
    , JoinGroupResponsePayload      (..)
    )
where


import           Control.Applicative
import           Data.Bits
import           Data.ByteString        (ByteString)
import qualified Data.ByteString        as BS
import           Data.Int
import           Data.Maybe
import           Data.Serialize
import           Data.Text              (Text)
import qualified Data.Text              as T
import           Data.Text.Encoding
import           Data.Vector            (Vector)
import qualified Data.Vector            as V
import           GHC.Generics
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


data ApiKey
    = ProduceKey
    | FetchKey
    | OffsetsKey
    | MetadataKey
    {- hide internal RPCs
    | LeaderAndIsrKey
    | StopReplicaKey
    | UpdateMetadataKey
    | ControlledShutdownKey
    -}
    | OffsetCommitKey
    | OffsetFetchKey
    | ConsumerMetadataKey
    | JoinGroupKey
    | HeartbeatKey
    deriving (Eq, Show)

instance Serialize ApiKey where
    put k = put $ case k of
        ProduceKey          -> 0 :: Int16
        FetchKey            -> 1
        OffsetsKey          -> 2
        MetadataKey         -> 3
        OffsetCommitKey     -> 8
        OffsetFetchKey      -> 9
        ConsumerMetadataKey -> 10
        JoinGroupKey        -> 11
        HeartbeatKey        -> 12

    get = (get :: Get Int16) >>= \k -> case k of
        0  -> return ProduceKey
        1  -> return FetchKey
        2  -> return OffsetsKey
        3  -> return MetadataKey
        8  -> return OffsetCommitKey
        9  -> return OffsetFetchKey
        10 -> return ConsumerMetadataKey
        11 -> return JoinGroupKey
        12 -> return HeartbeatKey

        _  -> fail "Invalid Api Key"


data RequestMessage a = RequestMessage
    { rq_apiKey        :: !Int16
    , rq_apiVersion    :: !Int16
    , rq_correlationId :: !Int32
    , rq_clientId      :: !ShortString
    , rq_request       :: !a
    } deriving (Eq, Show)

instance Serialize a => Serialize (RequestMessage a) where
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
        get' = RequestMessage <$> get <*> get <*> get <*> get <*> get


data ResponseMessage = ResponseMessage
    { rs_correlationId :: !Int32
    , rs_response      :: !Response
    } deriving (Eq, Show)

instance Serialize ResponseMessage where
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
        get' = ResponseMessage <$> get <*> get


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
    | Unknown
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
        Unknown                         -> -1
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

    get = (get :: Get Int16) >>= \code -> return $ case code of
        0  -> NoError
        1  -> OffsetOutOfRange
        2  -> InvalidMessage
        3  -> UnknownTopicOrPartition
        4  -> InvalidMessageSize
        5  -> LeaderNotAvailable
        6  -> NotLeaderForPartition
        7  -> RequestTimedOut
        8  -> BrokerNotAvailable
        9  -> ReplicaNotAvailable
        10 -> MessageSizeTooLarge
        11 -> StaleControllerEpoch
        12 -> OffsetMetadataTooLarge
        14 -> OffsetsLoadInProgress
        15 -> ConsumerCoordinatorNotAvailable
        16 -> NotCoordinatorForConsumer

        _  -> Unknown

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


data ProduceRequest = ProduceRequest
    { prq_requiredAcks :: !Int16
    , prq_timeout      :: !Int32
    , prq_payload      :: !(TopicKeyed ProduceRequestPayload)
    } deriving (Eq, Show, Generic)

instance Serialize ProduceRequest

data ProduceRequestPayload = ProduceRequestPayload
    { prqp_partition :: !Partition
    , prqp_size      :: !MessageSetSize
    , prqp_messages  :: !MessageSet
    } deriving (Eq, Show, Generic)

instance Serialize ProduceRequestPayload


data FetchRequest = FetchRequest
    { frq_replicaId   :: !NodeId
    , frq_maxWaitTime :: !Int32
    , frq_minBytes    :: !Int32
    , frq_topic       :: !TopicName
    , frq_partition   :: !Partition
    , frq_offset      :: !Int64
    , frq_maxBytes    :: !Int32
    } deriving (Eq, Show, Generic)

instance Serialize FetchRequest


data OffsetRequest = OffsetRequest
    { orq_replicaId :: !NodeId
    , orq_payload   :: !(TopicKeyed OffsetRequestPayload)
    } deriving (Eq, Show, Generic)

instance Serialize OffsetRequest


data OffsetRequestPayload = OffsetRequestPayload
    { orqp_partition  :: !Partition
    , orqp_time       :: !Int64
    , orqp_maxOffsets :: !Int32
    } deriving (Eq, Show, Generic)

instance Serialize OffsetRequestPayload


data MetadataRequest = MetadataRequest
    { mrq_topics :: !(Array TopicName)
    } deriving (Eq, Show, Generic)

instance Serialize MetadataRequest


--
-- v0 (kafka 0.8.1)
--
data OffsetCommitRequest = OffsetCommitRequest
    { ocrq_consumerGroup :: !ConsumerGroup
    , ocrq_payload       :: !(TopicKeyed OffsetCommitRequestPayload)
    } deriving (Eq, Show, Generic)

instance Serialize OffsetCommitRequest


data OffsetCommitRequestPayload = OffsetCommitRequestPayload
    { ocrqp_partition :: !Partition
    , ocrqp_offset    :: !Offset
    , ocrqp_metadata  :: !ShortString
    } deriving (Eq, Show, Generic)

instance Serialize OffsetCommitRequestPayload

--
-- v1 (kafka 0.8.2)
--
data OffsetCommitRequest_V1 = OffsetCommitRequest_V1
    { ocrq1_consumerGroup   :: !ConsumerGroup
    , ocrq1_groupGeneration :: !Int32
    , ocrq1_consumerId      :: !ShortString
    , ocrq1_payload         :: !(TopicKeyed OffsetCommitRequestPayload_V1)
    } deriving (Eq, Show, Generic)

instance Serialize OffsetCommitRequest_V1


data OffsetCommitRequestPayload_V1 = OffsetCommitRequestPayload_V1
    { ocrqp1_partition :: !Partition
    , ocrqp1_offset    :: !Offset
    , ocrqp1_timestamp :: !Int64
    , ocrqp1_metadata  :: !ShortString
    } deriving (Eq, Show, Generic)

instance Serialize OffsetCommitRequestPayload_V1


--
-- v2 (kafka 0.8.3)
--
data OffsetCommitRequest_V2 = OffsetCommitRequest_V2
    { ocrqp2_consumerGroup   :: !ConsumerGroup
    , ocrqp2_groupGeneration :: !Int32
    , ocrqp2_consumerId      :: !ShortString
    , ocrqp2_retentionTime   :: !Int64
    , ocrqp2_payload         :: !(TopicKeyed OffsetCommitRequestPayload) -- payload is the same as v0
    } deriving (Eq, Show, Generic)

instance Serialize OffsetCommitRequest_V2


data OffsetFetchRequest = OffsetFetchRequest
    { ofrq_consumerGroup :: !ConsumerGroup
    , ofrq_payload       :: !(TopicKeyed Partition)
    } deriving (Eq, Show, Generic)

instance Serialize OffsetFetchRequest


data ConsumerMetadataRequest = ConsumerMetadataRequest
    { cmrq_consumerGroup :: !ConsumerGroup
    } deriving (Eq, Show, Generic)

instance Serialize ConsumerMetadataRequest


data HeartbeatRequest = HeartbeatRequest
    { hrq_consumerGroup   :: !ConsumerGroup
    , hrq_groupGeneration :: !Int32
    , hrq_consumerId      :: !ShortString
    } deriving (Eq, Show, Generic)

instance Serialize HeartbeatRequest


data JoinGroupRequest = JoinGroupRequest
    { jgrq_consumerGroup               :: !ConsumerGroup
    , jgrq_sessionTimeout              :: !Int32
    , jgrq_topics                      :: !(Array TopicName)
    , jgrq_consumerId                  :: !ShortString
    , jgrq_partitionAssignmentStrategy :: !ShortString
    } deriving (Eq, Show, Generic)

instance Serialize JoinGroupRequest


data Broker = Broker !NodeId !Host !Port
    deriving (Eq, Show, Generic)

instance Serialize Broker


data TopicMetadata = TopicMetadata
    { topic_errorCode     :: !ErrorCode
    , topic_topic         :: !TopicName
    , topic_partitionMeta :: !(Array PartitionMetadata)
    } deriving (Eq, Show, Generic)

instance Serialize TopicMetadata


data PartitionMetadata = PartitionMetadata
    { part_errorCode   :: !ErrorCode
    , part_partitionId :: !Partition
    , part_leader      :: !NodeId
    , part_replicas    :: !(Array NodeId)
    , part_isr         :: !(Array NodeId)
    } deriving (Eq, Show, Generic)

instance Serialize PartitionMetadata


data ProduceResponsePayload = ProduceResponsePayload
    { prsp_partition :: !Partition
    , prsp_errorCode :: !ErrorCode
    , prsp_offset    :: !Offset
    } deriving (Eq, Show, Generic)

instance Serialize ProduceResponsePayload


data FetchResponsePayload = FetchResponsePayload
    { frsp_partition      :: !Partition
    , frsp_errorCode      :: !ErrorCode
    , frsp_offset         :: !Offset
    , frsp_messageSetSize :: !Int32
    , frsp_messageSet     :: !MessageSet
    } deriving (Eq, Show, Generic)

instance Serialize FetchResponsePayload


data OffsetResponsePayload = OffsetResponsePayload
    { orsp_partition :: !Partition
    , orsp_errorCode :: !ErrorCode
    , orsp_offsets   :: !(Array Offset)
    } deriving (Eq, Show, Generic)

instance Serialize OffsetResponsePayload


data OffsetCommitResponsePayload = OffsetCommitResponsePayload
    { ocrsp_partition :: !Partition
    , ocrsp_errorCode :: !ErrorCode
    } deriving (Eq, Show, Generic)

instance Serialize OffsetCommitResponsePayload


data OffsetFetchResponsePayload = OffsetFetchResponsePayload
    { ofrsp_partition :: !Partition
    , ofrsp_offset    :: !Offset
    , ofrsp_metadata  :: !ShortString
    , ofrsp_errorCode :: !ErrorCode
    } deriving (Eq, Show, Generic)

instance Serialize OffsetFetchResponsePayload


data JoinGroupResponsePayload = JoinGroupResponsePayload
    { jgrsp_errorCode          :: !ErrorCode
    , jgrsp_groupGeneration    :: !Int32
    , jgrsp_consumerId         :: !ShortString
    , jgrsp_assignedPartitions :: !(TopicKeyed Partition)
    } deriving (Eq, Show, Generic)

instance Serialize JoinGroupResponsePayload


data Response
    = MetadataResponse         !(Array Broker) !(Array TopicMetadata)
    | ProduceResponse          !(TopicKeyed ProduceResponsePayload)
    | FetchResponse            !(TopicKeyed FetchResponsePayload)
    | OffsetResponse           !(TopicKeyed OffsetResponsePayload)
    | ConsumerMetadataResponse !ErrorCode !NodeId !Host !Port
    | OffsetCommitResponse     !(TopicKeyed OffsetResponsePayload)
    | OffsetFetchResponse      !(TopicKeyed OffsetResponsePayload)
    | HeartbeatResponse        !ErrorCode
    | JoinGroupResponse        !JoinGroupResponsePayload
    deriving (Eq, Show, Generic)

instance Serialize Response
