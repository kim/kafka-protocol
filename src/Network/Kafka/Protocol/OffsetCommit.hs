{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE KindSignatures      #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Network.Kafka.Protocol.OffsetCommit
where

import Data.Serialize
import Data.Vinyl
import Data.Word
import GHC.Generics
import GHC.TypeLits
import Network.Kafka.Protocol.Instances ()
import Network.Kafka.Protocol.Universe


-- | The current version (Kafka 0.8.2)
type OffsetCommitRequest = OffsetCommitRequest'V1

-- key: 8
newtype OffsetCommitRequest'V0 (key :: Nat) (version :: Nat)
    = OffsetCommitRequest'V0 (FieldRec '[ FConsumerGroup
                                        , FPayload OffsetCommitRequestPayload'V0
                                        ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (OffsetCommitRequest'V0 k v)

newtype OffsetCommitRequest'V1 (key :: Nat) (version :: Nat)
    = OffsetCommitRequest'V1 (FieldRec '[ FConsumerGroup
                                        , FGeneration
                                        , FConsumerId
                                        , FPayload OffsetCommitRequestPayload'V1
                                        ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (OffsetCommitRequest'V1 k v)

newtype OffsetCommitRequest'V2 (key :: Nat) (version :: Nat)
    = OffsetCommitRequest'V2 (FieldRec '[ FConsumerGroup
                                        , FGeneration
                                        , '("retention", Word64)
                                        , FPayload OffsetCommitRequestPayload'V0
                                        ])
    deriving (Eq, Show, Generic)

instance forall k v. (KnownNat k, KnownNat v) => Serialize (OffsetCommitRequest'V2 k v)


newtype OffsetCommitRequestPayload'V0
    = OffsetCommitRequestPayload'V0 (FieldRec '[ FPartition
                                               , FOffset
                                               , FMetadata
                                               ])
    deriving (Eq, Show, Generic)

instance Serialize OffsetCommitRequestPayload'V0


newtype OffsetCommitRequestPayload'V1
    = OffsetCommitRequestPayload'V1 (FieldRec '[ FPartition
                                               , FOffset
                                               , FTimestamp
                                               , FMetadata
                                               ])
    deriving (Eq, Show, Generic)

instance Serialize OffsetCommitRequestPayload'V1


newtype OffsetCommitResponse
    = OffsetCommitResponse (FieldRec '[ FPayload OffsetCommitResponsePayload ])
    deriving (Eq, Show, Generic)

instance Serialize OffsetCommitResponse


newtype OffsetCommitResponsePayload
    = OffsetCommitResponsePayload (FieldRec '[ FPartition, FErrorCode ])
    deriving (Eq, Show, Generic)

instance Serialize OffsetCommitResponsePayload
