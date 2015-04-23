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


module Network.Kafka.Protocol.Heartbeat
    ( HeartbeatRequest
    , HeartbeatRequestFields
    , heartbeatRequest

    , HeartbeatResponse
    , HeartbeatResponseFields
    )
where

import Control.Lens
import Data.Serialize
import Data.Vinyl
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe


type HeartbeatRequestFields = '[ FConsumerGroup, FGeneration, FConsumerId ]

-- key: 12
newtype HeartbeatRequest (key :: Nat) (version :: Nat)
    = HeartbeatRequest (FieldRec HeartbeatRequestFields)
    deriving (Eq, Show, Generic)

makeWrapped ''HeartbeatRequest
instance forall k v. (KnownNat k, KnownNat v) => Serialize (HeartbeatRequest k v)

heartbeatRequest :: FieldRec HeartbeatRequestFields -> HeartbeatRequest 12 0
heartbeatRequest = HeartbeatRequest


type HeartbeatResponseFields = '[ FErrorCode ]

newtype HeartbeatResponse = HeartbeatResponse (FieldRec HeartbeatResponseFields)
    deriving (Eq, Show, Generic)

makeWrapped ''HeartbeatResponse
instance Serialize HeartbeatResponse
