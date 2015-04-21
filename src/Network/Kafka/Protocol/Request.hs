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

mkRequest :: (KnownNat key, KnownNat version, Show (a key version))
          => Int32
          -> ShortString
          -> a key version
          -> Request (a key version)
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

apiKey :: forall a key version. (KnownNat key, KnownNat version)
       => a key version
       -> ApiKey
apiKey _ = ApiKey . fromInteger $ natVal (Proxy :: Proxy key)


newtype ApiVersion = ApiVersion Int16
    deriving (Eq, Show, Generic)

instance Serialize ApiVersion

apiVersion :: forall a key version. (KnownNat key, KnownNat version)
            => a key version
            -> ApiVersion
apiVersion _ = ApiVersion . fromInteger $ natVal (Proxy :: Proxy version)
