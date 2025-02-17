@[extern "myAdd"]
opaque myAdd : UInt32 → UInt32 → UInt32

@[extern "wasd"]
opaque wasd : UInt32 → UInt32

namespace Sqlite

private opaque Nonempty : NonemptyType

private def RawConn : Type := Sqlite.Nonempty.type

structure Connection where
  path : String
  conn : RawConn

instance : ToString Connection where
  toString (conn : Connection) := s!"Connection({conn.path})"

@[extern "lean_sqlite_initialize"]
private opaque initSqlite : IO Unit
builtin_initialize initSqlite

@[extern "lean_sqlite_open"]
private opaque openSqlite : String → IO RawConn

def connect (s : String) : IO Connection := do
  let raw ← openSqlite s
  pure { path := s, conn := raw }

end Sqlite
