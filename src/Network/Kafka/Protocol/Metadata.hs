-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE KindSignatures        #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}


module Network.Kafka.Protocol.Metadata
    ( MetadataRequest
    , MetadataRequestFields
    , metadataRequest

    , MetadataResponse
    , MetadataResponseFields

    , Broker
    , bHost
    , bNodeId
    , bPort

    , TopicMetadata
    , TopicMetadataFields

    , PartitionMetadata
    , PartitionMetadataFields

    , FBrokers
    , FISR
    , FLeader
    , FPartitionMetadata
    , FReplicas
    , FTopicMetadata
    , brokers
    , isr
    , leader
    , partitionMetadata
    , replicas
    , topicMetadata
    )
where

import Control.Lens
import Data.Proxy
import Data.Serialize
import Data.Vinyl
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


data Broker = Broker { _bNodeId :: !NodeId, _bHost :: !Host, _bPort :: !Port }
    deriving (Eq, Show, Generic)

makeLenses ''Broker
instance Serialize Broker


type FISR      = '("isr"     , Array NodeId)
type FLeader   = '("leader"  , NodeId)
type FReplicas = '("replicas", Array NodeId)

isr :: Proxy FISR
isr = Proxy

leader :: Proxy FLeader
leader = Proxy

replicas :: Proxy FReplicas
replicas = Proxy


type PartitionMetadataFields = '[ FErrorCode
                                , FPartition
                                , FLeader
                                , FReplicas
                                , FISR
                                ]

newtype PartitionMetadata = PartitionMetadata (FieldRec PartitionMetadataFields)
    deriving (Eq, Show, Generic)

makeWrapped ''PartitionMetadata
instance Serialize PartitionMetadata


type FPartitionMetadata = '("partition_metadata", Array PartitionMetadata)

partitionMetadata :: Proxy FPartitionMetadata
partitionMetadata = Proxy


type TopicMetadataFields = '[ FErrorCode, FTopic, FPartitionMetadata ]

newtype TopicMetadata = TopicMetadata (FieldRec TopicMetadataFields)
    deriving (Eq, Show, Generic)

makeWrapped ''TopicMetadata
instance Serialize TopicMetadata


type MetadataRequestFields = '[ FTopics ]

-- key: 3, version: 0
newtype MetadataRequest (key :: Nat) (version :: Nat)
    = MetadataRequest (FieldRec MetadataRequestFields)
    deriving (Eq, Show, Generic)

makeWrapped ''MetadataRequest
instance forall k v. (KnownNat k, KnownNat v) => Serialize (MetadataRequest k v)

metadataRequest :: FieldRec MetadataRequestFields -> MetadataRequest 3 0
metadataRequest = MetadataRequest


type FBrokers       = '("brokers"       , Array Broker)
type FTopicMetadata = '("topic_metadata", Array TopicMetadata)

brokers :: Proxy FBrokers
brokers = Proxy

topicMetadata :: Proxy FTopicMetadata
topicMetadata = Proxy

type MetadataResponseFields = '[ FBrokers, FTopicMetadata ]

newtype MetadataResponse = MetadataResponse (FieldRec MetadataResponseFields)
    deriving (Eq, Show, Generic)

makeWrapped ''MetadataResponse
instance Serialize MetadataResponse
