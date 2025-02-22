import Lake
open System Lake DSL

package sqlite

lean_lib Sqlite

@[default_target]
lean_exe sqlite where
  root := `Main
  moreLinkArgs := #["-lsqlite3"]

lean_exe Tests.Sqlite where
  moreLinkArgs := #["-lsqlite3"]

target sqliteffi.o pkg : FilePath := do
  let oFile := pkg.buildDir / "native" / "sqliteffi.o"
  let srcJob ← inputTextFile <| pkg.dir / "native" / "ffi.c"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString, "-I/nix/store/8r55amvr43sm771rgm0sszd05rm8j1cr-sqlite-3.46.0-dev/include/"]
  buildO oFile srcJob weakArgs #["-fPIC"] "clang" getLeanTrace

extern_lib libsqliteffi pkg := do
  let ffiO ← sqliteffi.o.fetch
  let name := nameToStaticLib "sqliteffi"
  buildStaticLib (pkg.nativeLibDir / name) #[ffiO]

require LSpec from git
  "https://github.com/argumentcomputer/lspec/" @ "8a51034d049c6a229d88dd62f490778a377eec06"
