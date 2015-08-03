{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DefaultSignatures #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}

{-# OPTIONS_GHC -fno-warn-unrecognised-pragmas #-}

module System.Console.GetOpt.Generics.Simple where

import           Generics.SOP
import           System.Environment

import           System.Console.GetOpt.Generics.GetArguments
import           System.Console.GetOpt.Generics.Modifier
import           System.Console.GetOpt.Generics.Result

class (All Option (ArgumentTypes main)) =>
  SimpleCLI main where
  {-# MINIMAL _initialFieldStates, _run #-}
  type ArgumentTypes main :: [*]
  _initialFieldStates :: Proxy main -> NP FieldState (ArgumentTypes main)
  _run :: NP I (ArgumentTypes main) -> main -> IO ()

-- | 'simpleCLI' converts an IO operation into a program with a proper CLI.
--   Retrieves command line arguments through 'withArgs'.
--   @main@ (the given IO operation) can have arbitrarily many parameters
--   provided all parameters have an instance for 'Option'.
--
--   May throw the following exceptions:
--
--   - @'ExitFailure' 1@ in case of invalid options. Error messages are written
--     to @stderr@.
--   - @'ExitSuccess'@ in case @--help@ is given. (@'ExitSuccess'@ behaves like
--     a normal exception, except that -- if uncaught -- the process will exit
--     with exit-code @0@.) Help output is written to @stdout@.
--
--   Example:

-- ### Start "docs/SimpleExample.hs" Haddock ###
-- ### End ###

-- | Using the above program in bash:

-- ### Start "docs/SimpleExample.bash-protocol" Haddock ###
-- ### End ###

simpleCLI :: forall main . (SimpleCLI main) => main -> IO ()
simpleCLI main = do
  args <- getArgs
  progName <- getProgName
  let result = do
        outputInfo progName (mkModifiers []) args
          (hliftA (const $ Comp NoSelector)
            (_initialFieldStates (Proxy :: Proxy main)))
        filledIn <- fillInPositionalArguments args
          (_initialFieldStates (Proxy :: Proxy main))
        collectResult filledIn
  f <- handleResult result
  _run f main

instance SimpleCLI (IO ()) where
  type ArgumentTypes (IO ()) = '[]
  _initialFieldStates Proxy = Nil
  _run Nil = id
  _run _ = impossible "_run"

instance (Option a, SimpleCLI rest) =>
  SimpleCLI (a -> rest) where
    type ArgumentTypes (a -> rest) = a ': ArgumentTypes rest
    _initialFieldStates Proxy = PositionalArgument :* _initialFieldStates (Proxy :: Proxy rest)
    _run (I a :* r) main = _run r (main a)
    _run _ _ = impossible "_run"
