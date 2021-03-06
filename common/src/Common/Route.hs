{-# LANGUAGE EmptyCase             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE KindSignatures        #-}
{-# LANGUAGE LambdaCase            #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE PolyKinds             #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TemplateHaskell       #-}
{-# LANGUAGE TypeFamilies          #-}

module Common.Route where

import           Control.Lens                  hiding (bimap)
import           Obelisk.Route
import           Prelude                       hiding (id, (.))

import           Control.Categorical.Bifunctor (bimap)
import           Control.Category              ((.))
import           Data.Functor.Identity         (Identity)
import           Data.Functor.Sum              (Sum (InL, InR))
import           Data.Text                     (Text)

import           Obelisk.Route.TH              (deriveRouteComponent)

newtype DocumentSlug = DocumentSlug { unDocumentSlug :: Text } deriving (Eq, Ord, Show)
makeWrapped ''DocumentSlug
newtype Username = Username { unUsername :: Text } deriving (Eq, Ord, Show)
makeWrapped ''Username

data BackendRoute :: * -> * where
  -- | Used to handle unparseable routes.
  BackendRoute_Missing :: BackendRoute ()
  -- You can define any routes that will be handled specially by the backend here.
  -- i.e. These do not serve the frontend, but do something different, such as serving static files.

data FrontendRoute :: * -> * where
  FrontendRoute_Home :: FrontendRoute ()
  FrontendRoute_Login :: FrontendRoute ()
  FrontendRoute_Register :: FrontendRoute ()
  FrontendRoute_Settings :: FrontendRoute ()
  FrontendRoute_Editor :: FrontendRoute (Maybe DocumentSlug)
  FrontendRoute_Article :: FrontendRoute DocumentSlug
  FrontendRoute_Profile :: FrontendRoute (Username, Maybe (R ProfileRoute))
  -- This type is used to define frontend routes, i.e. ones for which the backend will serve the frontend.

data ProfileRoute :: * -> * where
  ProfileRoute_Favourites :: ProfileRoute ()

backendRouteEncoder
  :: Encoder (Either Text) Identity (R (Sum BackendRoute (ObeliskRoute FrontendRoute))) PageName
backendRouteEncoder = handleEncoder (const (InL BackendRoute_Missing :/ ())) $
  pathComponentEncoder $ \case
    InL backendRoute -> case backendRoute of
      BackendRoute_Missing -> PathSegment "missing" $ unitEncoder mempty
    InR obeliskRoute -> obeliskRouteSegment obeliskRoute $ \case
      -- The encoder given to PathEnd determines how to parse query parameters,
      -- in this example, we have none, so we insist on it.
      FrontendRoute_Home -> PathEnd $ unitEncoder mempty
      FrontendRoute_Login -> PathSegment "login" $ unitEncoder mempty
      FrontendRoute_Register -> PathSegment "register" $ unitEncoder mempty
      FrontendRoute_Settings -> PathSegment "settings" $ unitEncoder mempty
      FrontendRoute_Editor -> PathSegment "editor" $ maybeEncoder (unitEncoder mempty) (singlePathSegmentEncoder . unwrappedEncoder)
      FrontendRoute_Article -> PathSegment "article" $ singlePathSegmentEncoder . unwrappedEncoder
      FrontendRoute_Profile -> PathSegment "profile" $
        let profileRouteEncoder = pathComponentEncoder $ \case
              ProfileRoute_Favourites -> PathSegment "favourites" $ unitEncoder mempty
        in ( pathSegmentEncoder . bimap unwrappedEncoder (maybeEncoder (unitEncoder mempty) profileRouteEncoder ) )

concat <$> mapM deriveRouteComponent
  [ ''BackendRoute
  , ''FrontendRoute
  , ''ProfileRoute
  ]
