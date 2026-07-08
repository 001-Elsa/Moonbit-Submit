# Release Notes

## 0.1.1

MoonPack 0.1.1 refreshes the contest package after documentation, acceptance
checklist, example documentation, formatting, and the larger `demo.world`
generated package were added.

```text
001-Elsa/moonpack@0.1.1
```

Verify the published package with:

```powershell
moon fetch 001-Elsa/moonpack@0.1.1
```

## 0.1.0

MoonPack 0.1.0 is the first contest-ready release published as:

```text
001-Elsa/moonpack@0.1.0
```

Verify the published package with:

```powershell
moon fetch 001-Elsa/moonpack@0.1.0
```

## Release Checklist

Run the following commands before publishing or submitting a new acceptance build:

```powershell
moon update
moon check
moon test
moon package --list
```

The package should include source code, examples, generated demo files,
documentation, the proposal, and the root `LICENSE`. It should not include local
toolchains, dependency caches, build output, downloaded archives, or generated
interface files.

## Repository Links

- GitHub: https://github.com/001-Elsa/Moonbit-Submit
- Gitlink: https://gitlink.org.cn/Hanzzz/MoonPack_Hz
- Mooncakes package: `001-Elsa/moonpack@0.1.1`
