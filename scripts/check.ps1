$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$env:MOON_HOME = Join-Path $root ".moonhome"
$env:PATH = (Join-Path $env:MOON_HOME "bin") + ";" + $env:PATH

moon version --all
moon check
moon test
moon run src/cli -- check examples/auth/auth.mpack
moon run src/cli -- check examples/savegame/savegame.mpack
moon run src/cli -- compat examples/compat/savegame_v1.mpack examples/compat/savegame_v2.mpack
moon run src/cli -- gen examples/savegame/savegame.mpack -o generated
moon check
moon test

$invalidOutput = moon run src/cli -- check examples/invalid/reserved.mpack 2>&1
if ($LASTEXITCODE -eq 0) {
  throw "invalid schema unexpectedly passed"
}
if (-not ($invalidOutput -join "`n").Contains("examples/invalid/reserved.mpack:5:3")) {
  throw "invalid schema did not report path:line:column"
}
Write-Output $invalidOutput

$badCompatOutput = moon run src/cli -- compat examples/compat/savegame_v1.mpack examples/compat/savegame_bad.mpack 2>&1
if ($LASTEXITCODE -eq 0) {
  throw "incompatible schema unexpectedly passed"
}
if (-not ($badCompatOutput -join "`n").Contains("removed field 2 without reserving it")) {
  throw "compat check did not report removed unreserved field"
}
Write-Output $badCompatOutput
