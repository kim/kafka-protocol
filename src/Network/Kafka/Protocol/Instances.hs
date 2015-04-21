{-# LANGUAGE BangPatterns         #-}
{-# LANGUAGE DataKinds            #-}
{-# LANGUAGE FlexibleContexts     #-}
{-# LANGUAGE FlexibleInstances    #-}
{-# LANGUAGE GADTs                #-}
{-# LANGUAGE PolyKinds            #-}
{-# LANGUAGE ScopedTypeVariables  #-}
{-# LANGUAGE TypeOperators        #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}

module Network.Kafka.Protocol.Instances
where

import Control.Applicative
import Data.Serialize
import Data.Vinyl
import GHC.TypeLits


instance forall s t. (KnownSymbol s, Serialize t) => Serialize (ElField '(s,t)) where
    put (Field x) = put x
    get = Field <$> get

instance Serialize (Rec f '[]) where
    put RNil = return ()
    get = return RNil

instance (Serialize (f r), Serialize (Rec f rs)) => Serialize (Rec f (r ': rs)) where
    put (!x :& xs) = put x *> put xs
    {-# INLINE put #-}
    get = (:&) <$> get <*> get
    {-# INLINE get #-}

