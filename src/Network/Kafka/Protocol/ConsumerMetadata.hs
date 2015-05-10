-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds #-}


module Network.Kafka.Protocol.ConsumerMetadata
    ( ConsumerMetadataRequest
    , ConsumerMetadataRequestFields
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

import Data.Proxy
import Data.Word
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe


type ConsumerMetadataRequestFields = '[ FConsumerGroup ]
type ConsumerMetadataRequest       = Req 10 0 ConsumerMetadataRequestFields


type FCoordinatorId   = '("coordinator_id"  , Word32)
type FCoordinatorHost = '("coordinator_host", Host)
type FCoordinatorPort = '("coordinator_port", Port)

coordinatorId :: Proxy FCoordinatorId
coordinatorId = Proxy

coordinatorHost :: Proxy FCoordinatorHost
coordinatorHost = Proxy

coordinatorPort :: Proxy FCoordinatorPort
coordinatorPort = Proxy


type ConsumerMetadataResponseFields =
    '[ FErrorCode, FCoordinatorId, FCoordinatorHost, FCoordinatorPort ]
type ConsumerMetadataResponse       = Resp ConsumerMetadataResponseFields
