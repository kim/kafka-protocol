-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}


module Network.Kafka.Protocol.Metadata
    ( MetadataRequest
    , MetadataRequestFields
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


type PartitionMetadataFields
    = '[ FErrorCode, FPartition, FLeader, FReplicas, FISR ]

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
type MetadataRequest       = Req 4 0 MetadataRequestFields


type FBrokers       = '("brokers"       , Array Broker)
type FTopicMetadata = '("topic_metadata", Array TopicMetadata)

brokers :: Proxy FBrokers
brokers = Proxy

topicMetadata :: Proxy FTopicMetadata
topicMetadata = Proxy

type MetadataResponseFields = '[ FBrokers, FTopicMetadata ]
type MetadataResponse       = Resp MetadataResponseFields
