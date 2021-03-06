{-# LANGUAGE DeriveAnyClass     #-}
{-# LANGUAGE DeriveGeneric      #-}
{-# LANGUAGE StandaloneDeriving #-}
module RealWorld.Conduit.Api.Articles.Articles where

import           Data.Aeson                             (FromJSON (..),
                                                         ToJSON (..))
import           GHC.Generics                           (Generic)

import           RealWorld.Conduit.Api.Articles.Article (Article)

data Articles = Articles
  { articles      :: [Article]
  , articlesCount :: Int
  }

deriving instance Generic Articles
deriving instance ToJSON Articles
deriving instance FromJSON Articles
