namespace Sqlite.FFI
namespace Constants

def SQLITE_OPEN_READONLY      : UInt32 := 1
def SQLITE_OPEN_READWRITE     : UInt32 := 2
def SQLITE_OPEN_CREATE        : UInt32 := 4
def SQLITE_OPEN_DELETEONCLOSE : UInt32 := 8
def SQLITE_OPEN_EXCLUSIVE     : UInt32 := 16
def SQLITE_OPEN_AUTOPROXY     : UInt32 := 32
def SQLITE_OPEN_URI           : UInt32 := 64
def SQLITE_OPEN_MEMORY        : UInt32 := 128
def SQLITE_OPEN_MAIN_DB       : UInt32 := 256
def SQLITE_OPEN_TEMP_DB       : UInt32 := 512
def SQLITE_OPEN_TRANSIENT_DB  : UInt32 := 1024
def SQLITE_OPEN_MAIN_JOURNAL  : UInt32 := 2048
def SQLITE_OPEN_TEMP_JOURNAL  : UInt32 := 4096
def SQLITE_OPEN_SUBJOURNAL    : UInt32 := 8192
def SQLITE_OPEN_SUPER_JOURNAL : UInt32 := 16384
def SQLITE_OPEN_NOMUTEX       : UInt32 := 32768
def SQLITE_OPEN_FULLMUTEX     : UInt32 := 65536
def SQLITE_OPEN_SHAREDCACHE   : UInt32 := 131072
def SQLITE_OPEN_PRIVATECACHE  : UInt32 := 262144
def SQLITE_OPEN_WAL           : UInt32 := 524288
def SQLITE_OPEN_NOFOLLOW      : UInt32 := 16777216
def SQLITE_OPEN_EXRESCODE     : UInt32 := 33554432

end Constants

private opaque Nonempty : NonemptyType

def RawConn : Type := Nonempty.type
def RawCursor : Type := Nonempty.type

structure Cursor where
  cursor : RawCursor
  step : IO Bool
  bindText : UInt32 → String → IO Unit
  bindInt : UInt32 → Int → IO Unit
  reset : IO Unit
  columnsCount : IO UInt32
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
private opaque sqliteOpen : String → UInt32 → IO RawConn

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
private opaque cursorColumnsCount : @&RawCursor → IO UInt32

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

def connect (s : String) (flags : UInt32) : IO Connection := do
  let rawconn ← sqliteOpen s flags
  pure { path := s,
         conn := rawconn,
         prepare := (sqlitePrepareWrap rawconn ·) }

end Sqlite.FFI
