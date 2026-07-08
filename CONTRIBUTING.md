# Contributing

MoonPack is currently a contest-focused MoonBit project, so changes should keep
the package easy to verify and publish.

## Development Checks

Run these commands before committing:

```powershell
moon check
moon test
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

Use `moon package --list` before publishing to confirm the package does not
include local caches, build output, or toolchain downloads.

## Commit Guidelines

- Keep commits meaningful and reviewable.
- Prefer small commits that each explain one project improvement.
- Do not add empty commits only to increase history length.
- Keep generated demo files in sync when code generation behavior changes.

## Branch And Release Notes

- Keep GitHub `main` and Gitlink `main` synchronized.
- Keep Gitlink `master` synchronized too, because it is the default branch.
- Publish releases through `moon publish` after `moon check` and `moon test`
  pass.
- Record package-facing release details in `docs/release.md`.
