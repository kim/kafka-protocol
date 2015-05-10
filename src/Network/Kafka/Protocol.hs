-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE TypeFamilies #-}


-- | Implementation of the <http://kafka.apache.org Kafka> wire protocol
--
-- cf. <https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol>
--
module Network.Kafka.Protocol
    ( module Network.Kafka.Protocol.ConsumerMetadata
    , module Network.Kafka.Protocol.Fetch
    , module Network.Kafka.Protocol.Heartbeat
    , module Network.Kafka.Protocol.JoinGroup
    , module Network.Kafka.Protocol.Message
    , module Network.Kafka.Protocol.Metadata
    , module Network.Kafka.Protocol.Offset
    , module Network.Kafka.Protocol.OffsetCommit
    , module Network.Kafka.Protocol.OffsetFetch
    , module Network.Kafka.Protocol.Primitive
    , module Network.Kafka.Protocol.Produce
    , module Network.Kafka.Protocol.Request
    , module Network.Kafka.Protocol.Response
    , module Network.Kafka.Protocol.Universe

    , module Data.Vinyl

    , fields
    )
where

import Data.Vinyl
import Network.Kafka.Protocol.ConsumerMetadata
import Network.Kafka.Protocol.Fetch
import Network.Kafka.Protocol.Heartbeat
import Network.Kafka.Protocol.JoinGroup
import Network.Kafka.Protocol.Message
import Network.Kafka.Protocol.Metadata
import Network.Kafka.Protocol.Offset
import Network.Kafka.Protocol.OffsetCommit
import Network.Kafka.Protocol.OffsetFetch
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Produce
import Network.Kafka.Protocol.Request
import Network.Kafka.Protocol.Response
import Network.Kafka.Protocol.Universe
import Network.Kafka.Protocol.Internal         (fields)
