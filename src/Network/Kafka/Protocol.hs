-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE TypeFamilies #-}


-- | Implementation of the <http://kafka.apache.org Kafka> wire protocol
--
-- cf. <https://cwiki.apache.org/confluence/display/KAFKA/A+Guide+To+The+Kafka+Protocol>
--
module Network.Kafka.Protocol
    ( module Export
    , module Data.Vinyl

    , fields
    )
where

import Data.Vinyl
import Network.Kafka.Protocol.ConsumerMetadata as Export
import Network.Kafka.Protocol.Fetch            as Export
import Network.Kafka.Protocol.Heartbeat        as Export
import Network.Kafka.Protocol.JoinGroup        as Export
import Network.Kafka.Protocol.Message          as Export
import Network.Kafka.Protocol.Metadata         as Export
import Network.Kafka.Protocol.Offset           as Export
import Network.Kafka.Protocol.OffsetCommit     as Export
import Network.Kafka.Protocol.OffsetFetch      as Export
import Network.Kafka.Protocol.Primitive        as Export
import Network.Kafka.Protocol.Produce          as Export
import Network.Kafka.Protocol.Request          as Export
import Network.Kafka.Protocol.Response         as Export
import Network.Kafka.Protocol.Universe         as Export
import Network.Kafka.Protocol.Internal
