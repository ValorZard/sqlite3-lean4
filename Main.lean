import Sqlite

open IO

def double (f : Nat -> Nat) n := f (f n)
def inc := fun n => n + 1

def printUser (fuel : Nat) (cursor : Sqlite.FFI.Cursor) : IO Unit := do
  if fuel = 0 then
    pure ()
  else
    match ← cursor.step with
    | false => pure ()
    | true => do
      println s!"id  : {← cursor.columnInt 0}"
      println s!"name: {← cursor.columnText 1}"
      printUser (fuel - 1) cursor

def main : IO Unit := do
  let conn ← Sqlite.FFI.connect "test.sqlite3"
  match ← conn.exec "select count(1) from users;" with
  | Sqlite.FFI.Result.rows c =>
    println s!"{c.columnsCount}"
    match ← c.step with
    | false => println "error"
    | true => println "step"
    let count ← c.columnInt 0
    println s!"count: {count}"
    match ← conn.exec "select * from users;" with
     | Sqlite.FFI.Result.error e => println e
     | Sqlite.FFI.Result.ok => println "ok"
     | Sqlite.FFI.Result.rows c =>
       printUser count.toNat c
  | _ => println "error"
  println s!"Hello, {conn}"
