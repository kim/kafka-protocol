{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE GADTs               #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving  #-}

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
where

import Control.Applicative
import Data.Serialize
import Data.Vinyl
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe


type OffsetFetchRequest = OffsetFetchRequest' 9 1

offsetFetchRequest :: FieldRec '[ FConsumerGroup, FPayload Partition ]
                   -> OffsetFetchRequest
offsetFetchRequest = OffsetFetchRequest'V1

data OffsetFetchRequest' (key :: Nat) (version :: Nat) where
    OffsetFetchRequest'V0 :: FieldRec '[ FConsumerGroup, FPayload Partition ]
                          -> OffsetFetchRequest' 9 0

    OffsetFetchRequest'V1 :: FieldRec '[ FConsumerGroup, FPayload Partition ]
                          -> OffsetFetchRequest' 9 1

deriving instance Eq   (OffsetFetchRequest' k v)
deriving instance Show (OffsetFetchRequest' k v)

instance Serialize (OffsetFetchRequest' 9 0) where
    put (OffsetFetchRequest'V0 rec) = put rec
    get = OffsetFetchRequest'V0 <$> get

instance Serialize (OffsetFetchRequest' 9 1) where
    put (OffsetFetchRequest'V1 rec) = put rec
    get = OffsetFetchRequest'V1 <$> get


newtype OffsetFetchResponse
    = OffsetFetchResponse (FieldRec '[ FPayload OffsetFetchResponsePayload ])
    deriving (Eq, Show, Generic)

instance Serialize OffsetFetchResponse

newtype OffsetFetchResponsePayload
    = OffsetFetchResponsePayload (FieldRec '[ FPartition
                                            , FOffset
                                            , FMetadata
                                            , FErrorCode
                                            ])
    deriving (Eq, Show, Generic)

instance Serialize OffsetFetchResponsePayload
