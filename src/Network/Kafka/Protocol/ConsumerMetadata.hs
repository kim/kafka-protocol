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


module Network.Kafka.Protocol.ConsumerMetadata
    ( ConsumerMetadataRequest
    , ConsumerMetadataRequestFields
    , consumerMetadataRequest

    , ConsumerMetadataResponse
    , ConsumerMetadataResponseFields

    , FCoordinatorId
    , FCoordinatorHost
    , FCoordinatorPort
    , coordinatorId
    , coordinatorHost
    , coordinatorPort
    )
where

import Control.Lens
import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


type ConsumerMetadataRequestFields = '[ FConsumerGroup ]

-- key: 10
newtype ConsumerMetadataRequest (key :: Nat) (version :: Nat)
    = ConsumerMetadataRequest (FieldRec ConsumerMetadataRequestFields)
    deriving (Eq, Show, Generic)

makeWrapped ''ConsumerMetadataRequest
instance forall k v. (KnownNat k, KnownNat v) => Serialize (ConsumerMetadataRequest k v)

consumerMetadataRequest :: FieldRec ConsumerMetadataRequestFields
                        -> ConsumerMetadataRequest 10 0
consumerMetadataRequest = ConsumerMetadataRequest


type FCoordinatorId   = '("coordinator_id"  , Word32)
type FCoordinatorHost = '("coordinator_host", Host)
type FCoordinatorPort = '("coordinator_port", Port)

coordinatorId :: Proxy FCoordinatorId
coordinatorId = Proxy

coordinatorHost :: Proxy FCoordinatorHost
coordinatorHost = Proxy

coordinatorPort :: Proxy FCoordinatorPort
coordinatorPort :: Proxy


type ConsumerMetadataResponseFields = '[ FErrorCode
                                       , FCoordinatorId
                                       , FCoordinatorHost
                                       , FCoordinatorPort
                                       ]

newtype ConsumerMetadataResponse
    = ConsumerMetadataResponse (FieldRec ConsumerMetadataResponseFields)
    deriving (Eq, Show, Generic)

makeWrapped ''ConsumerMetadataResponse
instance Serialize ConsumerMetadataResponse
