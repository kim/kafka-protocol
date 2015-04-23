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


module Network.Kafka.Protocol.Produce
    ( ProduceRequest
    , ProduceRequestFields
    , produceRequest

    , ProduceRequestPayload
    , ProduceRequestPayloadFields
    , produceRequestPayload

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
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe


type FRequiredAcks = '("required_acks", Word16)
type FTimeout      = '("timeout"      , Word32)

requiredAcks :: Proxy FRequiredAcks
requiredAcks = Proxy

timeout :: Proxy FTimeout
timeout = Proxy


type ProduceRequestFields = '[ FRequiredAcks
                             , FTimeout
                             , FPayload ProduceRequestPayload
                             ]

newtype ProduceRequest (key :: Nat) (version :: Nat)
    = ProduceRequest (FieldRec ProduceRequestFields)
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (ProduceRequest k v)

produceRequest :: FieldRec ProduceRequestFields -> ProduceRequest 0 0
produceRequest = ProduceRequest


type ProduceRequestPayloadFields = '[ FPartition, FSize, FMessageSet ]

newtype ProduceRequestPayload
    = ProduceRequestPayload (FieldRec ProduceRequestPayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize ProduceRequestPayload

produceRequestPayload :: FieldRec ProduceRequestPayloadFields
                      -> ProduceRequestPayload
produceRequestPayload = ProduceRequestPayload

makeWrapped ''ProduceRequest
makeWrapped ''ProduceRequestPayload


type ProduceResponseFields ='[ FPayload ProduceResponsePayload ]

newtype ProduceResponse = ProduceResponse (FieldRec ProduceResponseFields)
    deriving (Eq, Show, Generic)

instance Serialize ProduceResponse

type ProduceResponsePayloadFields = '[ FPartition, FErrorCode, FOffset ]

newtype ProduceResponsePayload
    = ProduceResponsePayload (FieldRec ProduceResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize ProduceResponsePayload

makeWrapped ''ProduceResponse
makeWrapped ''ProduceResponsePayload
