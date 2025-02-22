import Sqlite
import LSpec

open LSpec
open Sqlite.FFI
open Sqlite.FFI.Constants

def assert := (· = true)

instance : Testable (assert b) :=
  if h : b = true then
    .isTrue h
  else
    .isFalse h s!"Expected true but got false"

structure TestContext where
  conn : Connection

def setup (s : String) : IO TestContext := do
  let flags := SQLITE_OPEN_READWRITE ||| SQLITE_OPEN_CREATE
  let conn ← connect s flags

  match ← conn.prepare "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT NOT NULL);" with
  | Except.ok cursor => cursor.step
  | Except.error _ => pure false

  match ← conn.prepare "INSERT INTO users (id, name) VALUES (1, 'John Doe');" with
  | Except.ok cursor => cursor.step
  | Except.error _ => pure false

  pure ⟨conn⟩

def cleanup (ctx : TestContext) : IO Unit := do
  match ← ctx.conn.prepare "DROP TABLE IF EXISTS users;" with
  | Except.ok cursor => do
    let _ ← cursor.step
    pure ()
  | Except.error _ => pure ()

def withTest (test : TestContext → IO Bool) : IO Bool := do
  let ctx ← setup "test.sqlite3"
  try
    let result ← test ctx
    cleanup ctx
    pure result
  catch e =>
    IO.println s!"Error: {e}"
    cleanup ctx
    pure false

def testInsertData (ctx : TestContext) : IO Bool := do
  match ← ctx.conn.prepare "INSERT INTO users (id, name) VALUES (?, ?);" with
  | Except.ok cursor =>
    cursor.bindInt 1 2
    cursor.bindText 2 "Jane Doe"
    let _ ← cursor.step
    pure true
  | Except.error _ => pure false

def testSelectData (ctx : TestContext) : IO Bool := do
  match ← ctx.conn.prepare "SELECT * FROM users WHERE id = 1;" with
  | Except.ok cursor =>
    let hasRow ← cursor.step
    if hasRow then
      let id ← cursor.columnInt 0
      let name ← cursor.columnText 1
      pure (id = 1 && name == "John Doe")
    else
      pure false
  | Except.error _ => pure false

def testParameterBinding (ctx : TestContext) : IO Bool := do
  match ← ctx.conn.prepare "SELECT * FROM users WHERE id = ? AND name = ?;" with
  | Except.ok cursor =>
    cursor.bindInt 1 1
    cursor.bindText 2 "John Doe"
    pure true
  | Except.error _ => pure false

def testColumnCount (ctx : TestContext) : IO Bool := do
  match ← ctx.conn.prepare "SELECT * FROM users;" with
  | Except.ok cursor =>
    let count ← cursor.columnsCount
    pure (count = 2)
  | Except.error _ => pure false

def testInvalidSyntax (ctx : TestContext) : IO Bool := do
  match ← ctx.conn.prepare "INVALID SQL QUERY;" with
  | Except.error _ => pure true
  | Except.ok _ => pure false

def testNonExistentTable (ctx : TestContext) : IO Bool := do
  match ← ctx.conn.prepare "SELECT * FROM non_existent_table;" with
  | Except.error _ => pure true
  | Except.ok _ => pure false

def main := do
  let insertData ← (withTest testInsertData)
  let selectData ← (withTest testSelectData)
  let parameterBinding ← (withTest testParameterBinding)
  let columnCount ← (withTest testColumnCount)
  let invalidSyntax ← (withTest testInvalidSyntax)
  let nonExistentTable ← (withTest testNonExistentTable)

  lspecIO $
    test "can insert data" (assert insertData) $
    test "can select data" (assert selectData) $
    test "can bind parameters" (assert parameterBinding) $
    test "can get column count" (assert columnCount) $
    test "handles invalid SQL syntax" (assert invalidSyntax) $
    test "handles non-existent table" (assert nonExistentTable)
