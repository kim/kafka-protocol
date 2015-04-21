-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}


module Network.Kafka.Protocol.JoinGroup
where

import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


-- key: 11
newtype JoinGroupRequest (key :: Nat) (version :: Nat)
    = JoinGroupRequest (FieldRec '[ FConsumerGroup
                                  , '("session_timeout", Word32)
                                  , FTopics
                                  , FConsumerId
                                  , '("partition_assignment_strategy", ShortString)
                                  ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (JoinGroupRequest k v)

newtype JoinGroupResponse
    = JoinGroupResponse (FieldRec '[ FErrorCode
                                   , FGeneration
                                   , FConsumerId
                                   , '("assigned_partitions", TopicKeyed Partition)
                                   ])
    deriving (Eq, Show, Generic)

instance Serialize JoinGroupResponse
