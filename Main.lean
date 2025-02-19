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
      println s!"id: {← cursor.columnInt 0} | name: {← cursor.columnText 1}"
      printUser (fuel - 1) cursor

def main : IO Unit := do
  let conn ← Sqlite.FFI.connect "test.sqlite3"
  match ← conn.prepare "insert into users values (?, ?);" with
  | Except.error e => println s!"error {e}"
  | Except.ok c =>
    c.bindInt 1 154
    c.bindText 2 "giga chad"
    printUser 10 c
  println "----------------------------------------------------------------"
  match ← conn.prepare "select count(1) from users;" with
  | Except.ok c =>
    println s!"{c.columnsCount}"
    match ← c.step with
    | false => println "error"
    | true => println "step"
    let count ← c.columnInt 0
    println s!"count: {count}"
    match ← conn.prepare "select * from users;" with
     | Except.error e => println e
     | Except.ok c =>
       printUser count.toNat c
  | Except.error e => println s!"error: {e}"
  println s!"Hello, {conn}"
