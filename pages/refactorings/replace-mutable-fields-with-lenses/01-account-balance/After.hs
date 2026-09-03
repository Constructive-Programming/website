-- Same, with a lens on the balance: the getter and the pure setter
-- packed as one value.
module After where

data Account = Account { balance :: Int, bonus :: Int }
  deriving (Eq, Show)

data Lens s a = Lens { get :: s -> a, set :: a -> s -> s }

modify :: Lens s a -> (a -> a) -> s -> s
modify l f s = set l (f (get l s)) s

balanceLens :: Lens Account Int
balanceLens = Lens { get = balance, set = \b a -> a { balance = b } }

withdraw :: Account -> Int -> Account
withdraw a amount = modify balanceLens (subtract amount) a
