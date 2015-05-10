-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds #-}

module Network.Kafka.Protocol.Heartbeat
    ( HeartbeatRequest
    , HeartbeatRequestFields
    , HeartbeatResponse
    , HeartbeatResponseFields
    )
where

import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe


type HeartbeatRequestFields = '[ FConsumerGroup, FGeneration, FConsumerId ]
type HeartbeatRequest       = Req 12 0 HeartbeatRequestFields


type HeartbeatResponseFields = '[ FErrorCode ]
type HeartbeatResponse       = Resp HeartbeatResponseFields
