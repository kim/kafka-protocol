-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE DeriveGeneric       #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Network.Kafka.Protocol.Request
where

import           Control.Applicative
import qualified Data.ByteString                  as BS
import           Data.Int
import           Data.Proxy
import           Data.Serialize
import           GHC.Generics
import           GHC.TypeLits
import           Network.Kafka.Protocol.Primitive
import           Network.Kafka.Protocol.Universe


data Request a = Request
    { rq_apiKey        :: !ApiKey
    , rq_apiVersion    :: !ApiVersion
    , rq_correlationId :: !Int32
    , rq_clientId      :: !ShortString
    , rq_request       :: !a
    } deriving (Eq, Show)

instance Serialize a => Serialize (Request a) where
    put rq = do
        put (fromIntegral (BS.length rq') :: Int32)
        put rq'
      where
        rq' = runPut (put rq)

    get = do
        len <- get :: Get Int32
        bs  <- getBytes (fromIntegral len)
        either fail return $ runGet get' bs
      where
        get' = Request <$> get <*> get <*> get <*> get <*> get

mkRequest :: (KnownNat key, KnownNat version)
          => Int32
          -> ShortString
          -> Req key version a
          -> Request (Req key version a)
mkRequest correlationId clientId rq = Request
    { rq_apiKey        = apiKey rq
    , rq_apiVersion    = apiVersion rq
    , rq_correlationId = correlationId
    , rq_clientId      = clientId
    , rq_request       = rq
    }

newtype ApiKey = ApiKey Int16
    deriving (Eq, Show, Generic)

instance Serialize ApiKey

apiKey :: forall key version a. (KnownNat key, KnownNat version)
       => Req key version a
       -> ApiKey
apiKey _ = ApiKey . fromInteger $ natVal (Proxy :: Proxy key)


newtype ApiVersion = ApiVersion Int16
    deriving (Eq, Show, Generic)

instance Serialize ApiVersion

apiVersion :: forall key version a. (KnownNat key, KnownNat version)
            => Req key version a
            -> ApiVersion
apiVersion _ = ApiVersion . fromInteger $ natVal (Proxy :: Proxy version)
