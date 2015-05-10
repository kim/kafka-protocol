-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}


-- | OffsetFetch
--
-- Note that:
--
-- @
-- version 0 and 1 have exactly the same wire format, but different functionality.
-- version 0 will read the offsets from ZK and version 1 will read the offsets from Kafka.
-- @
--
-- (cf.  <https://github.com/apache/kafka/blob/0.8.2/core/src/main/scala/kafka/api/OffsetFetchRequest.scala>)
module Network.Kafka.Protocol.OffsetFetch
    ( OffsetFetchRequest
    , OffsetFetchRequestFields

    , OffsetFetchRequest'V0
    , OffsetFetchRequest'V1

    , OffsetFetchResponse
    , OffsetFetchResponseFields

    , OffsetFetchResponsePayload
    , OffsetFetchResponsePayloadFields
    )
where

import Control.Lens
import Data.Serialize
import Data.Vinyl
import GHC.Generics
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe


type OffsetFetchRequestFields = '[ FConsumerGroup, FPayload Partition ]
type OffsetFetchRequest       = OffsetFetchRequest'V1

type OffsetFetchRequest'V0 = Req 9 0 OffsetFetchRequestFields
type OffsetFetchRequest'V1 = Req 9 1 OffsetFetchRequestFields


type OffsetFetchResponseFields = '[ FPayload OffsetFetchResponsePayload ]
type OffsetFetchResponse       = Resp OffsetFetchResponseFields

type OffsetFetchResponsePayloadFields
    = '[ FPartition, FOffset, FMetadata, FErrorCode ]

newtype OffsetFetchResponsePayload
    = OffsetFetchResponsePayload (FieldRec OffsetFetchResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetFetchResponsePayload

makeWrapped ''OffsetFetchResponsePayload
