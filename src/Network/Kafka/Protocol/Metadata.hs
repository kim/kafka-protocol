{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Network.Kafka.Protocol.Metadata
    ( MetadataRequest (..)
    , MetadataResponse (..)
    , Broker (..)
    , TopicMetadata (..)
    , PartitionMetadata (..)
    )
where

import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


-- key: 3, version: 0
newtype MetadataRequest (key :: Nat) (version :: Nat)
    = MetadataRequest (FieldRec '[ FTopics ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (MetadataRequest k v)


newtype MetadataResponse
    = MetadataResponse (FieldRec '[ '("brokers"       , Array Broker)
                                  , '("topic_metadata", Array TopicMetadata)
                                  ])
    deriving (Eq, Show, Generic)

instance Serialize MetadataResponse

type NodeId = Word32
type Host   = ShortString
type Port   = Word32

data Broker = Broker !NodeId !Host !Port
    deriving (Eq, Show, Generic)

instance Serialize Broker

newtype TopicMetadata
    = TopicMetadata (FieldRec '[ FErrorCode
                               , FTopic
                               , '("partition_metadata", Array PartitionMetadata)
                               ])
    deriving (Eq, Show, Generic)

instance Serialize TopicMetadata

newtype PartitionMetadata
    = PartitionMetadata (FieldRec '[ FErrorCode
                                   , FPartition
                                   , '("leader"  , NodeId)
                                   , '("replicas", Array NodeId)
                                   , '("isr"     , Array NodeId)
                                   ])
    deriving (Eq, Show, Generic)

instance Serialize PartitionMetadata
