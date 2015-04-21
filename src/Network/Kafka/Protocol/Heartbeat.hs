-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}


module Network.Kafka.Protocol.Heartbeat
where

import Data.Serialize
import Data.Vinyl
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe

-- key: 12
newtype HeartbeatRequest (key :: Nat) (version :: Nat)
    = HeartbeatRequest (FieldRec '[ FConsumerGroup
                                  , FGeneration
                                  , FConsumerId
                                  ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (HeartbeatRequest k v)


newtype HeartbeatResponse = HeartbeatResponse (FieldRec '[FErrorCode])
    deriving (Eq, Show, Generic)

instance Serialize HeartbeatResponse
