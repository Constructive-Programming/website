-- Withdraw from an account: the balance changes, the bonus does not.
module Before where

data Account = Account { balance :: Int, bonus :: Int }

withdraw :: Account -> Int -> Account
withdraw a amount = a { balance = balance a - amount }
