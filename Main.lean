import FFI

open IO

def double (f : Nat -> Nat) n := f (f n)
def inc := fun n => n + 1

def main : IO Unit := do
  let conn ← Sqlite.connect "test.sqlite3"
  println s!"Hello, {double inc 100} {myAdd 1 1} {myAdd 1 1} {myAdd 1 1} {wasd 2} {conn}"
