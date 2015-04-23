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
{-# LANGUAGE StandaloneDeriving    #-}
{-# LANGUAGE GADTs                 #-}


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
    , offsetFetchRequest

    , offsetFetchRequest'V0
    , offsetFetchRequest'V1

    , OffsetFetchResponse
    , OffsetFetchResponseFields

    , OffsetFetchResponsePayload
    , OffsetFetchResponsePayloadFields
    )
where

import Control.Applicative
import Control.Lens
import Data.Serialize
import Data.Vinyl
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe
import Network.Kafka.Protocol.Internal


type OffsetFetchRequestFields = '[ FConsumerGroup, FPayload Partition ]

data OffsetFetchRequest (key :: Nat) (version :: Nat) where
    OffsetFetchRequest'V0 :: FieldRec OffsetFetchRequestFields
                          -> OffsetFetchRequest 9 0

    OffsetFetchRequest'V1 :: FieldRec OffsetFetchRequestFields
                          -> OffsetFetchRequest 9 1

deriving instance Eq   (OffsetFetchRequest k v)
deriving instance Show (OffsetFetchRequest k v)

instance Wrapped (OffsetFetchRequest 9 0) where
    type Unwrapped (OffsetFetchRequest 9 0) = FieldRec OffsetFetchRequestFields
    _Wrapped' = iso (\ (OffsetFetchRequest'V0 fs) -> fs) OffsetFetchRequest'V0

instance Wrapped (OffsetFetchRequest 9 1) where
    type Unwrapped (OffsetFetchRequest 9 1) = FieldRec OffsetFetchRequestFields
    _Wrapped' = iso (\ (OffsetFetchRequest'V1 fs) -> fs) OffsetFetchRequest'V1

instance Serialize (OffsetFetchRequest 9 0) where
    put = put . fields
    get = OffsetFetchRequest'V0 <$> get

instance Serialize (OffsetFetchRequest 9 1) where
    put = put . fields
    get = OffsetFetchRequest'V1 <$> get

offsetFetchRequest    :: FieldRec OffsetFetchRequestFields
                      -> OffsetFetchRequest 9 1
offsetFetchRequest    = offsetFetchRequest'V1
offsetFetchRequest'V0 :: FieldRec OffsetFetchRequestFields
                      -> OffsetFetchRequest 9 0
offsetFetchRequest'V0 = OffsetFetchRequest'V0
offsetFetchRequest'V1 :: FieldRec OffsetFetchRequestFields
                      -> OffsetFetchRequest 9 1
offsetFetchRequest'V1 = OffsetFetchRequest'V1


type OffsetFetchResponseFields = '[ FPayload OffsetFetchResponsePayload ]

newtype OffsetFetchResponse
    = OffsetFetchResponse (FieldRec OffsetFetchResponseFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetFetchResponse

type OffsetFetchResponsePayloadFields = '[ FPartition
                                         , FOffset
                                         , FMetadata
                                         , FErrorCode
                                         ]

newtype OffsetFetchResponsePayload
    = OffsetFetchResponsePayload (FieldRec OffsetFetchResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetFetchResponsePayload

makeWrapped ''OffsetFetchResponse
makeWrapped ''OffsetFetchResponsePayload
