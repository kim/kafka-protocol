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


module Network.Kafka.Protocol.Offset
    ( OffsetRequest
    , OffsetRequestFields
    , offsetRequest

    , OffsetRequestPayload
    , OffsetRequestPayloadFields
    , offsetRequestPayload

    , OffsetResponse
    , OffsetResponseFields

    , OffsetResponsePayload
    , OffsetResponsePayloadFields

    , FMaxOffsets
    , FOffsets
    , FTime
    , maxOffsets
    , offsets
    , time
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


type OffsetRequestFields = '[ FReplicaId, FPayload OffsetRequestPayload ]

newtype OffsetRequest (key :: Nat) (version :: Nat)
    = OffsetRequest (FieldRec OffsetRequestFields)
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (OffsetRequest k v)

offsetRequest :: FieldRec OffsetRequestFields -> OffsetRequest 2 0
offsetRequest = OffsetRequest


type FMaxOffsets = '("max_offsets", Word32)
type FTime       = '("time"       , Word64)

maxOffsets :: Proxy FMaxOffsets
maxOffsets = Proxy

time :: Proxy FTime
time = Proxy


type OffsetRequestPayloadFields = '[ FPartition, FTime, FMaxOffsets ]

newtype OffsetRequestPayload
    = OffsetRequestPayload (FieldRec OffsetRequestPayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetRequestPayload

makeWrapped ''OffsetRequest
makeWrapped ''OffsetRequestPayload

offsetRequestPayload :: FieldRec OffsetRequestPayloadFields -> OffsetRequestPayload
offsetRequestPayload = OffsetRequestPayload


type OffsetResponseFields = '[ FPayload OffsetRequestPayload ]

newtype OffsetResponse = OffsetResponse (FieldRec OffsetResponseFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetResponse


type FOffsets = '("offsets", Array Word64)

offsets :: Proxy FOffsets
offsets = Proxy


type OffsetResponsePayloadFields = '[ FPartition, FErrorCode, FOffsets ]

newtype OffsetResponsePayload
    = OffsetResponsePayload (FieldRec OffsetResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetResponsePayload

makeWrapped ''OffsetResponse
makeWrapped ''OffsetResponsePayload
