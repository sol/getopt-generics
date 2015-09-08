{-# LANGUAGE DeriveGeneric #-}

module ModifiersSpec.RenameOptionsSpec where

import           Data.Char
import           Data.List
import qualified GHC.Generics
import           Test.Hspec

import           SimpleCLI
import           Util

data Foo
  = Foo {
    foo :: Int,
    bar :: Int
  }
  deriving (Eq, Show, GHC.Generics.Generic)

instance Generic Foo
instance HasDatatypeInfo Foo

data CommonPrefixes
  = CP {
    prefixFoo :: Int,
    prefixBar :: Int,
    notPrefixBaz :: Int
  }
  deriving (Eq, Show, GHC.Generics.Generic)

instance Generic CommonPrefixes
instance HasDatatypeInfo CommonPrefixes

spec :: Spec
spec = do
  describe "RenameOptions" $ do
    it "allows to rename all flags" $ do
      modsParse [RenameOptions (Just . reverse)] "--oof 1 --rab 2"
        `shouldBe` Success (Foo 1 2)

    it "works on camelCase field names" $ do
      modsParse
          [RenameOptions (Just . map toLower)]
          "--prefixfoo 1 --prefixbar 2 --notprefixbaz 3"
        `shouldBe` Success (CP 1 2 3)

    it "missing options messages show renamed options" $ do
      let Errors errs = modsParse
            [RenameOptions (Just . map toLower)] "" :: Result CommonPrefixes
      errs `shouldSatisfy` ("missing option: --prefixfoo=INTEGER" `elem`)

    it "can be used to rename a single field" $ do
      let rename f = case f of
            "foo" -> Just "renamed"
            _ -> Nothing
      modsParse [RenameOptions rename] "--renamed 1 --bar 2"
        `shouldBe` Success (Foo 1 2)

    it "allows to strip a common prefix" $ do
      modsParse [RenameOptions (stripPrefix "prefix")]
          "--foo 1 --bar 2 --not-prefix-baz 3"
        `shouldBe` Success (CP 1 2 3)
