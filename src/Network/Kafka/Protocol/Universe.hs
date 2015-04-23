{-# LANGUAGE DataKinds #-}

module Network.Kafka.Protocol.Universe
where

import Data.Proxy
import Data.Word
import Network.Kafka.Protocol.Message
import Network.Kafka.Protocol.Primitive


type TopicName     = ShortString
type TopicKeyed a  = Array (TopicName, Array a)
type Partition     = Word32
type NodeId        = Word32
type Host          = ShortString
type Port          = Word32


type FConsumerGroup = '("consumer_group", ShortString)
type FConsumerId    = '("consumer_id"   , ShortString)
type FErrorCode     = '("error_code"    , ErrorCode)
type FGeneration    = '("generation"    , Word32)
type FMessageSet    = '("messages"      , MessageSet)
type FMetadata      = '("metadata"      , ShortString)
type FOffset        = '("offset"        , Word64)
type FPartition     = '("partition"     , Word32)
type FPayload    a  = '("payload"       , TopicKeyed a)
type FReplicaId     = '("replica_id"    , Word32)
type FSize          = '("size"          , Word32)
type FTimestamp     = '("timestamp"     , Word64)
type FTopic         = '("topic"         , TopicName)
type FTopics        = '("topics"        , Array TopicName)

consumerGroup :: Proxy FConsumerGroup
consumerGroup = Proxy

consumerId :: Proxy FConsumerId
consumerId = Proxy

errorCode :: Proxy FErrorCode
errorCode = Proxy

generation :: Proxy FGeneration
generation = Proxy

messageSet :: Proxy FMessageSet
messageSet = Proxy

metadata :: Proxy FMetadata
metadata = Proxy

offset :: Proxy FOffset
offset = Proxy

partition :: Proxy FPartition
partition = Proxy

payload :: Proxy (FPayload a)
payload = Proxy

replicaId :: Proxy FReplicaId
replicaId = Proxy

size :: Proxy FSize
size = Proxy

timestamp :: Proxy FTimestamp
timestamp = Proxy

topic :: Proxy FTopic
topic = Proxy

topics :: Proxy FTopics
topics = Proxy
