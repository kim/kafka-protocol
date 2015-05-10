-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}


module Network.Kafka.Protocol.Produce
    ( ProduceRequest
    , ProduceRequestFields

    , ProduceRequestPayload
    , ProduceRequestPayloadFields

    , ProduceResponse
    , ProduceResponseFields

    , ProduceResponsePayload
    , ProduceResponsePayloadFields

    , FRequiredAcks
    , FTimeout
    , requiredAcks
    , timeout
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


type FRequiredAcks = '("required_acks", Word16)
type FTimeout      = '("timeout"      , Word32)

requiredAcks :: Proxy FRequiredAcks
requiredAcks = Proxy

timeout :: Proxy FTimeout
timeout = Proxy


type ProduceRequestFields
    = '[ FRequiredAcks, FTimeout, FPayload ProduceRequestPayload ]
type ProduceRequest = Req 0 0 ProduceRequestFields


type ProduceRequestPayloadFields = '[ FPartition, FSize, FMessageSet ]
type ProduceRequestPayload       = FieldRec ProduceRequestPayloadFields


type ProduceResponseFields ='[ FPayload ProduceResponsePayload ]
type ProduceResponse       = Resp ProduceResponseFields


type ProduceResponsePayloadFields = '[ FPartition, FErrorCode, FOffset ]

newtype ProduceResponsePayload
    = ProduceResponsePayload (FieldRec ProduceResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize ProduceResponsePayload

makeWrapped ''ProduceResponsePayload
