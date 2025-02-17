import FFI

open IO

def double (f : Nat -> Nat) n := f (f n)
def inc := fun n => n + 1

def main : IO Unit := do
  let conn ← Sqlite.connect "test.sqlite3"
  let a :=
    match ← Sqlite.exec conn "select 1 + 1;" with
     | Sqlite.Result.error e => e
     | _ => "ok"
  println s!"Hello, {conn} {a}"
