import Lake
open System Lake DSL

package sqlite

lean_lib Sqlite

def sqliteGitRepo := "https://github.com/SQLite/SQLite.git"
def sqliteGitBranch := "master"

-- TODO: at some point, we should figure out a better way to set the C compiler
def compiler := "cc"

target sqliteDir pkg : FilePath := do
  return .pure (pkg.dir / "vendor" / "sqlite")

def cloneGitRepo (repo : String) (branch : String) (dstDir : FilePath) : FetchM (Unit) := do
  let doesExist ← dstDir.pathExists
  if !doesExist then
    logInfo s!"Cloning {repo} into {dstDir}"
    let clone ← IO.Process.output { cmd := "git", args := #["clone", "--branch", branch, "--single-branch", "--depth", "1", "--recursive", repo, dstDir.toString] }
    if clone.exitCode != 0 then
      logError s!"Error cloning {repo}: {clone.stderr}"
    else
      logInfo s!"{repo} cloned successfully"
      logInfo clone.stdout
  else
    logInfo s!"Directory {dstDir} already exists, skipping clone"
  pure ()

def copyBinaries (sourceDir : FilePath) : FetchM (Unit) := do
  -- manually copy the DLLs we need to .lake/build/bin/ in the root directory for the library to work
  let dstDir := ((<- getRootPackage).binDir)
  IO.FS.createDirAll dstDir
  logInfo s!"Copying binaries from {sourceDir} to {dstDir}"
  let binariesDir : FilePath := sourceDir
  for entry in (← binariesDir.readDir) do
    if entry.path.extension != none then
      copyFile entry.path (dstDir / entry.path.fileName.get!)
  pure ()

def buildSqlite (repoDir : FilePath) (args : Array String): FetchM (Unit) := do
  logInfo s!"Building {repoDir} with args {args}"

  let configureBuild ← IO.Process.output {
    cmd := repoDir.toString ++ "/configure",
  }

  if configureBuild.exitCode != 0 then
    logError s!"Error configuring build: {configureBuild.stderr}"
    return ()
  else
    logInfo "Build configured successfully"

  -- Builds the "sqlite3" command-line tool
  let buildCommandLine ← IO.Process.output { cmd := "make", args := #[("CC=" ++ compiler), "sqlite3"] }
  if buildCommandLine.exitCode != 0 then
    logError s!"Error building project: {buildCommandLine.exitCode}"
    logError s!"Project build stderr: {buildCommandLine.stderr}"
    return ()

  let buildLib ← IO.Process.output { cmd := "make", args := #[("CC=" ++ compiler), "sqlite3.c"] }
  if buildLib.exitCode != 0 then
    logError s!"Error building project: {buildLib.exitCode}"
    logError s!"Project build stderr: {buildLib.stderr}"
    return ()

  logInfo s!"{repoDir} built successfully"

target sqliteffi.o pkg : FilePath := do
  let oFile := pkg.buildDir / "native" / "sqliteffi.o"
  let srcJob ← inputTextFile <| pkg.dir / "native" / "ffi.c"
  -- Use Lean include dir; avoid hardcoded Nix paths which don't exist on Windows
  let weakArgs := #["-I", (← getLeanIncludeDir).toString]
  -- Use configured compiler variable to allow Windows toolchains to choose the proper C compiler
  buildO oFile srcJob weakArgs #["-fPIC"] compiler getLeanTrace

extern_lib libsqlite pkg := do
  -- clone the git repositories we need so we can build them later
  let sqliteDir ← (← sqliteDir.fetch).await

  cloneGitRepo sqliteGitRepo sqliteGitBranch sqliteDir

  -- build all the libraries we need
  buildSqlite sqliteDir #[]

  logInfo "All libraries built successfully"

  copyBinaries sqliteDir

  let ffiO ← sqliteffi.o.fetch
  let name := nameToStaticLib "sqliteffi"
  buildStaticLib (pkg.staticLibDir / name) #[ffiO]

@[default_target]
lean_exe sqlite where
  root := `Main
  moreLinkObjs := #[libsqlite]
  moreLinkArgs := #["-lsqlite3"]

lean_exe Tests.Sqlite where
  moreLinkObjs := #[libsqlite]
  moreLinkArgs := #["-lsqlite3"]

require LSpec from git
  "https://github.com/argumentcomputer/lspec/" @ "8a51034d049c6a229d88dd62f490778a377eec06"
