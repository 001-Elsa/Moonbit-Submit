#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_MOON_HOME="$ROOT/.moonhome"
PARENT_MOON_HOME="$(cd "$ROOT/.." && pwd)/.moonhome"
RUN_UPDATE=0

if [[ "${1:-}" == "--update" ]]; then
  RUN_UPDATE=1
fi

if [[ -d "$LOCAL_MOON_HOME" ]]; then
  export MOON_HOME="$LOCAL_MOON_HOME"
  export PATH="$MOON_HOME/bin:$PATH"
elif [[ -d "$PARENT_MOON_HOME" ]]; then
  export MOON_HOME="$PARENT_MOON_HOME"
  export PATH="$MOON_HOME/bin:$PATH"
elif ! command -v moon >/dev/null 2>&1; then
  echo "MoonBit toolchain not found. Expected moon in PATH or .moonhome under project root or parent directory." >&2
  exit 1
fi

moon version --all
if [[ "$RUN_UPDATE" -eq 1 || "${CI:-}" == "true" ]]; then
  moon update
fi
moon check
moon build
moon test

moon run src/cli -- check examples/auth/auth.mpack
moon run src/cli -- check examples/savegame/savegame.mpack
moon run src/cli -- compat examples/compat/savegame_v1.mpack examples/compat/savegame_v2.mpack
moon run src/cli -- gen examples/savegame/savegame.mpack -o generated
moon run src/cli -- doc examples/savegame/savegame.mpack -o docs/generated
moon run src/cli -- check examples/world/world.mpack
moon run src/cli -- gen examples/world/world.mpack -o generated
moon run src/cli -- doc examples/world/world.mpack -o docs/generated

moon fmt
moon check
moon build
moon test
moon package --list

set +e
invalid_output="$(moon run src/cli -- check examples/invalid/reserved.mpack 2>&1)"
invalid_status=$?
set -e
if [[ $invalid_status -eq 0 ]]; then
  echo "invalid schema unexpectedly passed" >&2
  exit 1
fi
if [[ "$invalid_output" != *"examples/invalid/reserved.mpack:5:3"* ]]; then
  echo "invalid schema did not report path:line:column" >&2
  echo "$invalid_output"
  exit 1
fi
echo "$invalid_output"

set +e
bad_compat_output="$(moon run src/cli -- compat examples/compat/savegame_v1.mpack examples/compat/savegame_bad.mpack 2>&1)"
bad_compat_status=$?
set -e
if [[ $bad_compat_status -eq 0 ]]; then
  echo "incompatible schema unexpectedly passed" >&2
  exit 1
fi
if [[ "$bad_compat_output" != *"removed field 2 without reserving it"* ]]; then
  echo "compat check did not report removed unreserved field" >&2
  echo "$bad_compat_output"
  exit 1
fi
echo "$bad_compat_output"
