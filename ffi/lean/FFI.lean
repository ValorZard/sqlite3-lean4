@[extern "myAdd"]
opaque myAdd : UInt32 → UInt32 → UInt32

@[extern "wasd"]
opaque wasd : UInt32 → UInt32

namespace Sqlite

private opaque Nonempty : NonemptyType

private def RawConn : Type := Sqlite.Nonempty.type
private def Cursor : Type := Sqlite.Nonempty.type

structure Connection where
  path : String
  conn : RawConn

instance : ToString Connection where
  toString (conn : Connection) := s!"Connection({conn.path})"

inductive Result where
  | ok : Result
  | rows (c : Cursor) : Result
  | error (e : String) : Result

@[extern "lean_sqlite_initialize"]
private opaque initSqlite : IO Unit
builtin_initialize initSqlite

@[extern "lean_sqlite_open"]
private opaque openSqlite : String → IO RawConn

@[extern "lean_sqlite_exec"]
private opaque execSqlite : @&RawConn → String → IO Result

@[extern "lean_sqlite_step"]
private opaque stepSqlite : @&Cursor → IO (Option (Array String))

@[extern "lean_sqlite_reset_cursor"]
private opaque resetCursorSqlite : @&Cursor → IO Unit

def connect (s : String) : IO Connection := do
  let rawconn ← openSqlite s
  pure { path := s, conn := rawconn }

def exec (c : Connection) (query : String) : IO Result :=
  execSqlite c.conn query

def step (c : Cursor) : IO (Option (Array String)) :=
  stepSqlite c

def reset (c : Cursor) : IO Unit :=
  resetCursorSqlite c

end Sqlite
