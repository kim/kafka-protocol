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


module Network.Kafka.Protocol.OffsetCommit
    ( OffsetCommitRequest
    , OffsetCommitRequestFields
    , offsetCommitRequest

    , OffsetCommitRequest'V0Fields
    , offsetCommitRequest'V0
    , OffsetCommitRequest'V1Fields
    , offsetCommitRequest'V1
    , OffsetCommitRequest'V2Fields
    , offsetCommitRequest'V2

    , OffsetCommitRequestPayload
    , OffsetCommitRequestPayloadFields
    , offsetCommitRequestPayload

    , OffsetCommitRequestPayload'V0Fields
    , offsetCommitRequestPayload'V0
    , OffsetCommitRequestPayload'V1Fields
    , offsetCommitRequestPayload'V1

    , OffsetCommitResponse
    , OffsetCommitResponseFields

    , OffsetCommitResponsePayload
    , OffsetCommitResponsePayloadFields

    , FRetention
    , retention
    )
where

import Control.Applicative
import Control.Lens
import Data.Proxy
import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe
import Network.Kafka.Protocol.Internal


type FRetention = '("retention", Word64)

retention :: Proxy FRetention
retention = Proxy


type OffsetCommitRequestFields    = OffsetCommitRequest'V1Fields
type OffsetCommitRequest'V0Fields = '[ FConsumerGroup
                                     , FPayload (OffsetCommitRequestPayload 0)
                                     ]
type OffsetCommitRequest'V1Fields = '[ FConsumerGroup
                                     , FGeneration
                                     , FConsumerId
                                     , FPayload (OffsetCommitRequestPayload 1)
                                     ]
type OffsetCommitRequest'V2Fields = '[ FConsumerGroup
                                     , FGeneration
                                     , FRetention
                                     , FPayload (OffsetCommitRequestPayload 0)
                                     ]

data OffsetCommitRequest (key :: Nat) (version :: Nat) where
    OffsetCommitRequest'V0 :: FieldRec OffsetCommitRequest'V0Fields
                           -> OffsetCommitRequest 8 0

    OffsetCommitRequest'V1 :: FieldRec OffsetCommitRequest'V1Fields
                           -> OffsetCommitRequest 8 1

    OffsetCommitRequest'V2 :: FieldRec OffsetCommitRequest'V2Fields
                           -> OffsetCommitRequest 8 2

deriving instance Eq   (OffsetCommitRequest k v)
deriving instance Show (OffsetCommitRequest k v)

instance Wrapped (OffsetCommitRequest 8 0) where
    type Unwrapped (OffsetCommitRequest 8 0) = FieldRec OffsetCommitRequest'V0Fields
    _Wrapped' = iso (\ (OffsetCommitRequest'V0 fs) -> fs) OffsetCommitRequest'V0

instance Wrapped (OffsetCommitRequest 8 1) where
    type Unwrapped (OffsetCommitRequest 8 1) = FieldRec OffsetCommitRequest'V1Fields
    _Wrapped' = iso (\ (OffsetCommitRequest'V1 fs) -> fs) OffsetCommitRequest'V1

instance Wrapped (OffsetCommitRequest 8 2) where
    type Unwrapped (OffsetCommitRequest 8 2) = FieldRec OffsetCommitRequest'V2Fields
    _Wrapped' = iso (\ (OffsetCommitRequest'V2 fs) -> fs) OffsetCommitRequest'V2


instance Serialize (OffsetCommitRequest 8 0) where
    put = put . fields
    get = OffsetCommitRequest'V0 <$> get

instance Serialize (OffsetCommitRequest 8 1) where
    put = put . fields
    get = OffsetCommitRequest'V1 <$> get

instance Serialize (OffsetCommitRequest 8 2) where
    put = put . fields
    get = OffsetCommitRequest'V2 <$> get


offsetCommitRequest    :: FieldRec OffsetCommitRequestFields
                       -> OffsetCommitRequest 8 1
offsetCommitRequest    = offsetCommitRequest'V1
offsetCommitRequest'V0 :: FieldRec OffsetCommitRequest'V0Fields
                       -> OffsetCommitRequest 8 0
offsetCommitRequest'V0 = OffsetCommitRequest'V0
offsetCommitRequest'V1 :: FieldRec OffsetCommitRequest'V1Fields
                       -> OffsetCommitRequest 8 1
offsetCommitRequest'V1 = OffsetCommitRequest'V1
offsetCommitRequest'V2 :: FieldRec OffsetCommitRequest'V2Fields
                       -> OffsetCommitRequest 8 2
offsetCommitRequest'V2 = OffsetCommitRequest'V2



type OffsetCommitRequestPayloadFields    = OffsetCommitRequestPayload'V1Fields
type OffsetCommitRequestPayload'V0Fields = '[ FPartition, FOffset, FMetadata ]
type OffsetCommitRequestPayload'V1Fields = '[ FPartition
                                            , FOffset
                                            , FTimestamp
                                            , FMetadata
                                            ]



data OffsetCommitRequestPayload (version :: Nat) where
    OffsetCommitRequestPayload'V0 :: FieldRec OffsetCommitRequestPayload'V0Fields
                                  -> OffsetCommitRequestPayload 0

    OffsetCommitRequestPayload'V1 :: FieldRec OffsetCommitRequestPayload'V1Fields
                                  -> OffsetCommitRequestPayload 1

deriving instance Eq   (OffsetCommitRequestPayload v)
deriving instance Show (OffsetCommitRequestPayload v)

instance Wrapped (OffsetCommitRequestPayload 0) where
    type Unwrapped (OffsetCommitRequestPayload 0) = FieldRec OffsetCommitRequestPayload'V0Fields
    _Wrapped' = iso (\ (OffsetCommitRequestPayload'V0 fs) -> fs) OffsetCommitRequestPayload'V0

instance Wrapped (OffsetCommitRequestPayload 1) where
    type Unwrapped (OffsetCommitRequestPayload 1) = FieldRec OffsetCommitRequestPayload'V1Fields
    _Wrapped' = iso (\ (OffsetCommitRequestPayload'V1 fs) -> fs) OffsetCommitRequestPayload'V1

instance Serialize (OffsetCommitRequestPayload 0) where
    put = put . fields
    get = OffsetCommitRequestPayload'V0 <$> get

instance Serialize (OffsetCommitRequestPayload 1) where
    put = put . fields
    get = OffsetCommitRequestPayload'V1 <$> get

offsetCommitRequestPayload    :: FieldRec OffsetCommitRequestPayloadFields
                              -> OffsetCommitRequestPayload 1
offsetCommitRequestPayload    = offsetCommitRequestPayload'V1
offsetCommitRequestPayload'V0 :: FieldRec OffsetCommitRequestPayload'V0Fields
                              -> OffsetCommitRequestPayload 0
offsetCommitRequestPayload'V0 = OffsetCommitRequestPayload'V0
offsetCommitRequestPayload'V1 :: FieldRec OffsetCommitRequestPayload'V1Fields
                              -> OffsetCommitRequestPayload 1
offsetCommitRequestPayload'V1 = OffsetCommitRequestPayload'V1



type OffsetCommitResponseFields = '[ FPayload OffsetCommitResponsePayload ]

newtype OffsetCommitResponse
    = OffsetCommitResponse (FieldRec OffsetCommitResponseFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetCommitResponse


type OffsetCommitResponsePayloadFields = '[ FPartition, FErrorCode ]

newtype OffsetCommitResponsePayload
    = OffsetCommitResponsePayload (FieldRec OffsetCommitResponsePayloadFields)
    deriving (Eq, Show, Generic)

instance Serialize OffsetCommitResponsePayload

makeWrapped ''OffsetCommitResponse
makeWrapped ''OffsetCommitResponsePayload
