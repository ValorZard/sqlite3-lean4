namespace Sqlite.FFI

private opaque Nonempty : NonemptyType

def RawConn : Type := Nonempty.type
def RawCursor : Type := Nonempty.type

structure Cursor where
  cursor : RawCursor
  step : IO Bool
  bindText : UInt32 → String → IO Unit
  bindInt : UInt32 → Int → IO Unit
  reset : IO Unit
  columnsCount : UInt32
  columnText : UInt32 → IO String
  columnInt : UInt32 → IO Int

structure Connection where
  path : String
  conn : RawConn
  prepare : String → IO (Except String Cursor)

instance : ToString Connection where
  toString (conn : Connection) := s!"Connection('{conn.path}')"

@[extern "lean_sqlite_initialize"]
private opaque sqliteInit : IO Unit
builtin_initialize sqliteInit

@[extern "lean_sqlite_open"]
private opaque sqliteOpen : String → IO RawConn

@[extern "lean_sqlite_prepare"]
private opaque sqlitePrepare : @&RawConn → String → IO (Except String RawCursor)

@[extern "lean_sqlite_cursor_bind_text"]
private opaque cursorBindText : @&RawCursor → UInt32 → String → IO Unit

@[extern "lean_sqlite_cursor_bind_int"]
private opaque cursorBindInt : @&RawCursor → UInt32 → Int → IO Unit

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

private def sqlitePrepareWrap (conn : RawConn) (query : String) : IO (Except String Cursor) := do
  pure $ match ← sqlitePrepare conn query with
  | Except.ok c => pure { cursor := c,
                          step := cursorStep c,
                          bindText := cursorBindText c,
                          bindInt := cursorBindInt c,
                          reset := cursorReset c,
                          columnsCount := cursorColumnsCount c,
                          columnText := cursorColumnText c,
                          columnInt := cursorColumnInt c }
  | Except.error e => Except.error e

def connect (s : String) : IO Connection := do
  let rawconn ← sqliteOpen s
  pure { path := s,
         conn := rawconn,
         prepare := (sqlitePrepareWrap rawconn ·) }

end Sqlite.FFI
