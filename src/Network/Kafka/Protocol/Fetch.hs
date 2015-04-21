{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Network.Kafka.Protocol.Fetch
where

import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe


-- key: 1, version: 0
newtype FetchRequest (key :: Nat) (version :: Nat)
    = FetchRequest (FieldRec '[ FReplicaId
                              , '("max_wait_time", Word32)
                              , '("min_bytes"    , Word32)
                              , FTopic
                              , FPartition
                              , FOffset
                              , '("max_bytes"    , Word32)
                              ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (FetchRequest k v)


newtype FetchResponse
    = FetchResponse (FieldRec '[ FPayload FetchResponsePayload ])
    deriving (Eq, Show, Generic)

instance Serialize FetchResponse

newtype FetchResponsePayload
    = FetchResponsePayload (FieldRec '[ FPartition
                                      , FErrorCode
                                      , FOffset
                                      , FSize
                                      , FMessageSet
                                      ])
    deriving (Eq, Show, Generic)

instance Serialize FetchResponsePayload
