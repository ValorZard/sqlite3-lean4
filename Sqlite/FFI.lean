namespace Sqlite.FFI

private opaque Nonempty : NonemptyType

def RawConn : Type := Nonempty.type
def RawCursor : Type := Nonempty.type

structure Cursor where
  cursor : RawCursor
  step : IO Bool
  reset : IO Unit
  columnsCount : UInt32
  columnText : UInt32 → IO String
  columnInt : UInt32 → IO Int

inductive Result (t : Type) where
  | ok : Result t
  | rows (c : t) : Result t
  | error (e : String) : Result t

structure Connection where
  path : String
  conn : RawConn
  exec : String → IO (Result Cursor)

instance : ToString Connection where
  toString (conn : Connection) := s!"Connection('{conn.path}')"

@[extern "lean_sqlite_initialize"]
private opaque sqliteInit : IO Unit
builtin_initialize sqliteInit

@[extern "lean_sqlite_open"]
private opaque sqliteOpen : String → IO RawConn

@[extern "lean_sqlite_exec"]
private opaque sqliteExec : @&RawConn → String → IO (Result RawCursor)

@[extern "lean_sqlite_cursor_step"]
private opaque cursorStep : @&RawCursor → IO Bool

@[extern "lean_sqlite_cursor_reset"]
private opaque cursorReset : @&RawCursor → IO Unit

@[extern "lean_sqlite_cursor_columns_count"]
private opaque cursorColumnsCount : @&RawCursor → UInt32

@[extern "lean_sqlite_cursor_column_text"]
private opaque cursorColumnText : @&RawCursor → UInt32 → IO String

@[extern "lean_sqlite_cursor_column_int"]
private opaque cursorColumnInt : @&RawCursor → UInt32 → IO Int

def sqliteExecWrap (conn : RawConn) (query : String) : IO (Result Cursor) := do
  pure $ match ← sqliteExec conn query with
  | Result.rows c => Result.rows { cursor := c,
                                   step := cursorStep c,
                                   reset := cursorReset c,
                                   columnsCount := cursorColumnsCount c,
                                   columnText := cursorColumnText c,
                                   columnInt := cursorColumnInt c }
  | Result.ok => Result.ok
  | Result.error e => Result.error e

def connect (s : String) : IO Connection := do
  let rawconn ← sqliteOpen s
  pure { path := s,
         conn := rawconn,
         exec := (sqliteExecWrap rawconn ·) }

end Sqlite.FFI
