module Network.Kafka.Protocol.Response
where

import           Control.Applicative
import qualified Data.ByteString     as BS
import           Data.Int
import           Data.Serialize


data Response a = Response
    { rs_correlationId :: !Int32
    , rs_response      :: !a
    } deriving (Eq, Show)

instance Serialize a => Serialize (Response a) where
    put rs = do
        put (fromIntegral (BS.length rs') :: Int32)
        put rs'
      where
        rs' = runPut (put rs)

    get = do
        len <- get :: Get Int32
        bs  <- getBytes (fromIntegral len)
        either fail return $ runGet get' bs
      where
        get' = Response <$> get <*> get
