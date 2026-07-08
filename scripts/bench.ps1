$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$localMoonHome = Join-Path $root ".moonhome"
$parentMoonHome = Join-Path (Split-Path -Parent $root) ".moonhome"
if (Test-Path $localMoonHome) {
  $env:MOON_HOME = $localMoonHome
} elseif (Test-Path $parentMoonHome) {
  $env:MOON_HOME = $parentMoonHome
} else {
  throw "MoonBit toolchain not found. Expected .moonhome under project root or parent directory."
}
$env:PATH = (Join-Path $env:MOON_HOME "bin") + ";" + $env:PATH

Push-Location $root
try {
  $schema = "examples/savegame/savegame.mpack"
  $generated = "generated"
  $docs = "docs/generated"

  Write-Output "MoonPack benchmark smoke run"
  Write-Output "schema: $schema"

  $check = Measure-Command {
    moon run src/cli -- check $schema | Out-Null
  }

  $gen = Measure-Command {
    moon run src/cli -- gen $schema -o $generated | Out-Null
  }

  $doc = Measure-Command {
    moon run src/cli -- doc $schema -o $docs | Out-Null
  }

  $test = Measure-Command {
    moon test | Out-Null
  }

  $bytes = (Get-ChildItem -Recurse -File (Join-Path $root "generated/demo/savegame") |
    Measure-Object -Property Length -Sum).Sum

  Write-Output ("check_ms: " + [int]$check.TotalMilliseconds)
  Write-Output ("gen_ms: " + [int]$gen.TotalMilliseconds)
  Write-Output ("doc_ms: " + [int]$doc.TotalMilliseconds)
  Write-Output ("test_ms: " + [int]$test.TotalMilliseconds)
  Write-Output ("generated_source_bytes: " + $bytes)
}
finally {
  Pop-Location
}
