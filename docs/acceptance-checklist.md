# Acceptance Checklist

Use this checklist before submitting MoonPack for contest review.

## Required Checks

- `moon check` passes locally.
- `moon test` passes locally.
- GitHub Actions latest run passes on the default branch.
- GitHub and Gitlink point to the same latest commit.
- Gitlink default branch contains the full project, not only a placeholder README.
- The project is published as `001-Elsa/moonpack@0.1.0`.
- The package can be fetched with `moon fetch 001-Elsa/moonpack@0.1.0`.
- Root `LICENSE` is present and matches the `license` field in `moon.mod`.

## Package Cleanliness

The packaged module should include source, docs, examples, generated demo code,
and submission materials. It should not include:

- `_build/`
- `.moonhome/`
- `.mooncakes/`
- `.repos/`
- `node_modules/`
- downloaded zip archives
- `*.generated.mbti`

Check the package contents with:

```powershell
moon package --list
```

## Review Notes

MoonPack is an original MoonBit-native serialization toolkit. It references the
field-number and wire-type idea used by Protocol Buffers, but it does not copy
protobuf source code and does not aim for protobuf wire compatibility.
