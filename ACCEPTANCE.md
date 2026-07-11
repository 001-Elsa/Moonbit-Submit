# Acceptance Checklist

Use this file as the root-level submission checklist for MoonPack.

## Repository Links

- GitHub: https://github.com/001-Elsa/Moonbit-Submit
- Gitlink: https://gitlink.org.cn/Hanzzz/MoonPack_Hz
- GitHub Actions latest passing CI: https://github.com/001-Elsa/Moonbit-Submit/actions/runs/29161109332
- Mooncakes package: `001-Elsa/moonpack@0.1.1`

## Required Local Checks

The full local acceptance script passed on this workspace:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1 -Update
```

It covers:

- `moon update`
- `moon check`
- `moon build`
- `moon test`
- CLI schema checks
- CLI compatibility checks
- generated code refresh
- generated docs refresh
- `moon fmt`
- `moon package --list`

Latest observed result: 43 tests passed and package output was generated at
`_build\publish\001-Elsa-moonpack-0.1.1.zip`.

## Submission State

- Root `LICENSE` is present and matches `license = "Apache-2.0"` in `moon.mod`.
- `moon.mod` package name is `001-Elsa/moonpack`.
- GitHub `main` points to commit `36ae94b22728bd20cc6b01bef3539e2fbeaa1295`.
- Gitlink `main` and `master` point to the same commit locally.
- Generated sources and generated docs are committed and reproducible.
- Package cleanliness was checked by `moon package --list`; build/cache folders
  such as `_build`, `.moonhome`, `.mooncakes`, `.repos`, and `node_modules` are
  not part of the published package list.
