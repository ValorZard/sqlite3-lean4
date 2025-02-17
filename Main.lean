import FFI

open IO

def double (f : Nat -> Nat) n := f (f n)
def inc := fun n => n + 1

def main : IO Unit := do
  let conn ← Sqlite.connect "test.sqlite3"
  match ← Sqlite.exec conn "select 1 + 1 = 2;" with
     | Sqlite.Result.error e => println e
     | Sqlite.Result.ok => println "ok"
     | Sqlite.Result.rows c =>
       match ← Sqlite.step c with
        | some s => println s
        | none => println "none"
  println s!"Hello, {conn}"
