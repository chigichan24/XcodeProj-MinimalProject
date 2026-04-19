# XcodeProj-MinimalProject

Verifies that the `support-package-traits` branch of `../XcodeProj` correctly round-trips Swift Package traits (SE-0450) through `pbxproj`.

## Prerequisites

- Sibling checkout of XcodeProj on branch `support-package-traits`:
  ```
  ~/src/github.com/chigichan24/
    XcodeProj/                   (branch: support-package-traits)
    XcodeProj-MinimalProject/    (this repo)
  ```

## Run

```
swift run MinimalProject
```

## What it checks

| Phase | What |
|---|---|
| 1 | Decodes the bundled fixture and prints `traits` on each package reference |
| 2 | Writes the fixture back after setting Remote traits to `nil` / `[]` / `["SQLCipher"]`; greps the resulting `pbxproj` to show how each state serializes |
| 3 | Mutates Local `traits`, writes, reloads, and asserts the values persisted |
| 4 | Asserts the type-level invariant that `nil`, `[]`, and `["Foo"]` are all pairwise unequal on `XCRemoteSwiftPackageReference` |

Exits 0 if everything passes, 1 otherwise.

## Fixture

`Fixtures/ProjectWithSwiftPackageTraits.xcodeproj` is a copy of the fixture added in the XcodeProj branch under `Fixtures/iOS/`. Kept here so this repo can run standalone after cloning, without needing to look inside the XcodeProj checkout.
