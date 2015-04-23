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


module Network.Kafka.Protocol.JoinGroup
    ( JoinGroupRequest
    , JoinGroupRequestFields
    , joinGroupRequest

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

import Control.Lens
import Data.Proxy
import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


type FPartitionAssignmentStrategy = '("partition_assignment_strategy", ShortString)
type FSessionTimeout              = '("session_timeout"              , Word32)

partitionAssignmentStrategy :: Proxy FPartitionAssignmentStrategy
partitionAssignmentStrategy = Proxy

sessionTimeout :: Proxy FSessionTimeout
sessionTimeout = Proxy


type JoinGroupRequestFields = '[ FConsumerGroup
                               , FSessionTimeout
                               , FTopics
                               , FConsumerId
                               , FPartitionAssignmentStrategy
                               ]

-- key: 11
newtype JoinGroupRequest (key :: Nat) (version :: Nat)
    = JoinGroupRequest (FieldRec JoinGroupRequestFields)
    deriving (Eq, Show, Generic)

makeWrapped ''JoinGroupRequest
instance forall k v. (KnownNat k, KnownNat v) => Serialize (JoinGroupRequest k v)

joinGroupRequest :: FieldRec JoinGroupRequestFields -> JoinGroupRequest 11 0
joinGroupRequest = JoinGroupRequest


type FAssignedPartitions = '("assigned_partitions", TopicKeyed Partition)

assignedPartitions :: Proxy FAssignedPartitions
assignedPartitions = Proxy


type JoinGroupResponseFields = '[ FErrorCode
                                , FGeneration
                                , FConsumerId
                                , FAssignedPartitions
                                ]

newtype JoinGroupResponse = JoinGroupResponse (FieldRec JoinGroupResponseFields)
    deriving (Eq, Show, Generic)

makeWrapped ''JoinGroupResponse
instance Serialize JoinGroupResponse
