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


module Network.Kafka.Protocol.Fetch
    ( FetchRequest
    , FetchRequestFields
    , fetchRequest

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
import GHC.TypeLits
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


type FetchRequestFields = '[ FReplicaId
                           , FMaxWaitTime
                           , FMinBytes
                           , FTopic
                           , FPartition
                           , FOffset
                           , FMaxBytes
                           ]

-- key: 1, version: 0
newtype FetchRequest (key :: Nat) (version :: Nat)
    = FetchRequest (FieldRec FetchRequestFields)
    deriving (Eq, Show, Generic)

makeWrapped ''FetchRequest

instance forall k v. (KnownNat k, KnownNat v) => Serialize (FetchRequest k v)

fetchRequest :: FieldRec FetchRequestFields -> FetchRequest 1 0
fetchRequest = FetchRequest


type FetchResponseFields = '[ FPayload FetchResponsePayload ]

newtype FetchResponse = FetchResponse (FieldRec FetchResponseFields)
    deriving (Eq, Show, Generic)

instance Serialize FetchResponse


type FetchResponsePayloadFields = '[ FPartition
                                   , FErrorCode
                                   , FOffset
                                   , FSize
                                   , FMessageSet
                                   ]
newtype FetchResponsePayload
    = FetchResponsePayload (FieldRec FetchResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize FetchResponsePayload

makeWrapped ''FetchResponse
makeWrapped ''FetchResponsePayload
