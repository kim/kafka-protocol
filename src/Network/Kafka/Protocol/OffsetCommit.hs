-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}


module Network.Kafka.Protocol.OffsetCommit
    ( OffsetCommitRequest
    , OffsetCommitRequestFields

    , OffsetCommitRequest'V0
    , OffsetCommitRequest'V1
    , OffsetCommitRequest'V2
    , OffsetCommitRequest'V0Fields
    , OffsetCommitRequest'V1Fields
    , OffsetCommitRequest'V2Fields

    , OffsetCommitRequestPayload
    , OffsetCommitRequestPayloadFields

    , OffsetCommitRequestPayload'V0
    , OffsetCommitRequestPayload'V1
    , OffsetCommitRequestPayload'V0Fields
    , OffsetCommitRequestPayload'V1Fields

    , OffsetCommitResponse
    , OffsetCommitResponseFields

    , OffsetCommitResponsePayload
    , OffsetCommitResponsePayloadFields

    , FRetention
    , retention
    )
where

import Control.Lens
import Data.Proxy
import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe


type FRetention = '("retention", Word64)

retention :: Proxy FRetention
retention = Proxy


type OffsetCommitRequestFields        = OffsetCommitRequest'V1Fields
type OffsetCommitRequest              = OffsetCommitRequest'V1
type OffsetCommitRequestPayload       = OffsetCommitRequestPayload'V1
type OffsetCommitRequestPayloadFields = OffsetCommitRequestPayload'V1Fields


type OffsetCommitRequest'V0Fields
    = '[ FConsumerGroup
       , FPayload OffsetCommitRequestPayload'V0
       ]
type OffsetCommitRequest'V1Fields
    = '[ FConsumerGroup
       , FGeneration
       , FConsumerId
       , FPayload OffsetCommitRequestPayload'V1
       ]
type OffsetCommitRequest'V2Fields
    = '[ FConsumerGroup
       , FGeneration
       , FRetention
       , FPayload OffsetCommitRequestPayload'V0
       ]


type OffsetCommitRequest'V0 = Req 8 0 OffsetCommitRequest'V0Fields
type OffsetCommitRequest'V1 = Req 8 1 OffsetCommitRequest'V1Fields
type OffsetCommitRequest'V2 = Req 8 2 OffsetCommitRequest'V2Fields


type OffsetCommitRequestPayload'V0Fields
    = '[ FPartition, FOffset, FMetadata ]
type OffsetCommitRequestPayload'V1Fields
    = '[ FPartition, FOffset, FTimestamp, FMetadata ]

type OffsetCommitRequestPayload'V0 = FieldRec OffsetCommitRequestPayload'V0Fields
type OffsetCommitRequestPayload'V1 = FieldRec OffsetCommitRequestPayload'V1Fields


type OffsetCommitResponseFields = '[ FPayload OffsetCommitResponsePayload ]
type OffsetCommitResponse       = Resp OffsetCommitResponseFields


type OffsetCommitResponsePayloadFields = '[ FPartition, FErrorCode ]

newtype OffsetCommitResponsePayload
    = OffsetCommitResponsePayload (FieldRec OffsetCommitResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetCommitResponsePayload

makeWrapped ''OffsetCommitResponsePayload
