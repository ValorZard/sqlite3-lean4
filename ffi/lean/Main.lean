import FFI

open IO

def main : IO Unit := do
  println $ myAdd 1 2
  println $ myAdd 0 0

#check myAdd 1 2
