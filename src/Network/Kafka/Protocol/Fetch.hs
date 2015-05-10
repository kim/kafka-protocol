-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}


module Network.Kafka.Protocol.Fetch
    ( FetchRequest
    , FetchRequestFields
    , FetchResponse
    , FetchResponseFields
    , FetchResponsePayload
    , FetchResponsePayloadFields

    , FMaxBytes
    , FMaxWaitTime
    , FMinBytes
    , maxBytes
    , maxWaitTime
    , minBytes
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


type FMaxBytes    = '("max_bytes"    , Word32)
type FMaxWaitTime = '("max_wait_time", Word32)
type FMinBytes    = '("min_bytes"    , Word32)

maxBytes :: Proxy FMaxBytes
maxBytes = Proxy

maxWaitTime :: Proxy FMaxWaitTime
maxWaitTime = Proxy

minBytes :: Proxy FMinBytes
minBytes = Proxy


type FetchRequestFields
    = '[ FReplicaId
       , FMaxWaitTime
       , FMinBytes
       , FTopic
       , FPartition
       , FOffset
       , FMaxBytes
       ]

type FetchRequest = Req 1 0 FetchRequestFields


type FetchResponseFields = '[ FPayload FetchResponsePayload ]
type FetchResponse       = Resp FetchResponseFields


type FetchResponsePayloadFields
    = '[ FPartition
       , FErrorCode
       , FOffset
       , FSize
       , FMessageSet
       ]
newtype FetchResponsePayload
    = FetchResponsePayload (FieldRec FetchResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize FetchResponsePayload

makeWrapped ''FetchResponsePayload
