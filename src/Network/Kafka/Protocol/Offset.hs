-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}


module Network.Kafka.Protocol.Offset
    ( OffsetRequest
    , OffsetRequestFields
    , OffsetRequestPayload
    , OffsetRequestPayloadFields
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
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


type OffsetRequestFields = '[ FReplicaId, FPayload OffsetRequestPayload ]
type OffsetRequest       = Req 2 0 OffsetRequestFields


type FMaxOffsets = '("max_offsets", Word32)
type FTime       = '("time"       , Word64)

maxOffsets :: Proxy FMaxOffsets
maxOffsets = Proxy

time :: Proxy FTime
time = Proxy

type OffsetRequestPayloadFields = '[ FPartition, FTime, FMaxOffsets ]
type OffsetRequestPayload       = FieldRec OffsetRequestPayloadFields


type OffsetResponseFields = '[ FPayload OffsetRequestPayload ]
type OffsetResponse       = Resp OffsetResponseFields


type FOffsets = '("offsets", Array Word64)

offsets :: Proxy FOffsets
offsets = Proxy


type OffsetResponsePayloadFields = '[ FPartition, FErrorCode, FOffsets ]

newtype OffsetResponsePayload
    = OffsetResponsePayload (FieldRec OffsetResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetResponsePayload

makeWrapped ''OffsetResponsePayload
