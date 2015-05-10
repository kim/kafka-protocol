-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds #-}


module Network.Kafka.Protocol.JoinGroup
    ( JoinGroupRequest
    , JoinGroupRequestFields
    , JoinGroupResponse
    , JoinGroupResponseFields

    , FAssignedPartitions
    , FPartitionAssignmentStrategy
    , FSessionTimeout
    , assignedPartitions
    , partitionAssignmentStrategy
    , sessionTimeout
    )
where

import Data.Proxy
import Data.Word
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


type FPartitionAssignmentStrategy = '("partition_assignment_strategy", ShortString)
type FSessionTimeout              = '("session_timeout"              , Word32)

partitionAssignmentStrategy :: Proxy FPartitionAssignmentStrategy
partitionAssignmentStrategy = Proxy

sessionTimeout :: Proxy FSessionTimeout
sessionTimeout = Proxy


type JoinGroupRequestFields
    = '[ FConsumerGroup
       , FSessionTimeout
       , FTopics
       , FConsumerId
       , FPartitionAssignmentStrategy
       ]

type JoinGroupRequest = Req 11 0 JoinGroupRequestFields


type FAssignedPartitions = '("assigned_partitions", TopicKeyed Partition)

assignedPartitions :: Proxy FAssignedPartitions
assignedPartitions = Proxy


type JoinGroupResponseFields
    = '[ FErrorCode
       , FGeneration
       , FConsumerId
       , FAssignedPartitions
       ]
type JoinGroupResponse = Resp JoinGroupResponseFields
