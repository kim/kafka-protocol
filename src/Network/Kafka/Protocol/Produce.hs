{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Network.Kafka.Protocol.Produce
where

import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Primitive
import Network.Kafka.Protocol.Universe


newtype ProduceRequest (key :: Nat) (version :: Nat)
    = ProduceRequest (FieldRec '[ '("required_acks", Word16)
                                , '("timeout"      , Word32)
                                , FPayload ProduceRequestPayload
                                ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (ProduceRequest k v)

produceRequest :: Word16
               -> Word32
               -> Array (TopicName, Array ProduceRequestPayload)
               -> ProduceRequest 0 0
produceRequest ra t p = ProduceRequest $
    Field ra :& Field t :& Field p :& RNil

newtype ProduceRequestPayload
    = ProduceRequestPayload (FieldRec '[ FPartition, FSize, FMessageSet ])
    deriving (Eq, Show, Generic)

instance Serialize ProduceRequestPayload


newtype ProduceResponse
    = ProduceResponse (FieldRec '[ FPayload ProduceResponsePayload ])
    deriving (Eq, Show, Generic)

instance Serialize ProduceResponse

newtype ProduceResponsePayload
    = ProduceResponsePayload (FieldRec '[ FPartition, FErrorCode, FOffset ])
    deriving (Eq, Show, Generic)

instance Serialize ProduceResponsePayload
