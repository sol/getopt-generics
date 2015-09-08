
module SimpleCLI.Normalize (
  normalize,
 ) where

import           Data.Char

normalize :: String -> String
normalize s =
  if all (not . isAllowedChar) s
    then s
    else
      slugify $
      dropWhile (== '-') $
      filter isAllowedChar $
      map (\ c -> if c == '_' then '-' else c) $
      s
  where
    slugify (a : r)
      | isUpper a = slugify (toLower a : r)
    slugify (a : b : r)
      | isUpper b = a : '-' : slugify (toLower b : r)
      | otherwise = a : slugify (b : r)
    slugify x = x

isAllowedChar :: Char -> Bool
isAllowedChar c = (isAscii c && isAlphaNum c) || (c `elem` "-_")
