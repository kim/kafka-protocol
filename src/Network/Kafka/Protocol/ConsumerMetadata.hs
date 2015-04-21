-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}


module Network.Kafka.Protocol.ConsumerMetadata
where

import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


-- key: 10
newtype ConsumerMetadataRequest (key :: Nat) (version :: Nat)
    = ConsumerMetadataRequest (FieldRec '[ FConsumerGroup ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (ConsumerMetadataRequest k v)

newtype ConsumerMetadataResponse
    = ConsumerMetadataResponse (FieldRec '[ FErrorCode
                                          , '("coordinator_id"  , Word32)
                                          , '("coordinator_host", ShortString)
                                          , '("coordinator_port", Word32)
                                          ])
    deriving (Eq, Show, Generic)

instance Serialize ConsumerMetadataResponse
