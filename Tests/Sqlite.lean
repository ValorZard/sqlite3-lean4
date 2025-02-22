import LSpec

open LSpec

def fourIO : IO Nat :=
  pure 4

def fiveIO : IO Nat :=
  pure 5

def main := do
  let four ← fourIO
  let five ← fiveIO
  lspecIO $
    test "fourIO equals 4" (four = 4) $
    test "fiveIO equals 5" (five = 5)

#check main
#eval main

#lspec
  test "four equals four" (4 = 4) $
  test "five equals five" (5 = 5)
