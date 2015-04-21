-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}


module Network.Kafka.Protocol.Offset
where

import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


-- key: 2, version: 0
newtype OffsetRequest (key :: Nat) (version :: Nat)
    = OffsetRequest (FieldRec '[ FReplicaId, FPayload OffsetRequestPayload ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (OffsetRequest k v)

newtype OffsetRequestPayload
    = OffsetRequestPayload (FieldRec '[ FPartition
                                      , '("time"       , Word64)
                                      , '("max_offsets", Word32)
                                      ])
    deriving (Eq, Show, Generic)

instance Serialize OffsetRequestPayload


newtype OffsetResponse
    = OffsetResponse (FieldRec '[ FPayload OffsetResponsePayload ])
    deriving (Eq, Show, Generic)

instance Serialize OffsetResponse

newtype OffsetResponsePayload
    = OffsetResponsePayload (FieldRec '[ FPartition
                                       , FErrorCode
                                       , '("offsets", Array Word64)
                                       ])
    deriving (Eq, Show, Generic)

instance Serialize OffsetResponsePayload
