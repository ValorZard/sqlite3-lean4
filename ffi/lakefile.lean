import Lake
open System Lake DSL

package ffi where
  srcDir := "lean"

lean_lib FFI

@[default_target]
lean_exe test where
  root := `Main

target ffi.o pkg : FilePath := do
  let oFile := pkg.buildDir / "c" / "ffi.o"
  let srcJob ← inputTextFile <| pkg.dir / "c" / "ffi.c"
  let weakArgs := #["-I", (← getLeanIncludeDir).toString, "-I/nix/store/8r55amvr43sm771rgm0sszd05rm8j1cr-sqlite-3.46.0-dev/include/"]
  buildO oFile srcJob weakArgs #["-fPIC"] "clang" getLeanTrace

extern_lib libleanffi pkg := do
  let ffiO ← ffi.o.fetch
  let name := nameToStaticLib "leanffi"
  buildStaticLib (pkg.nativeLibDir / name) #[ffiO]
