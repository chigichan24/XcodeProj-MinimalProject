# XcodeProj-MinimalProject

Demonstrates the difference between stock `tuist/XcodeProj` 9.11.0 and the `support-package-traits` branch when round-tripping a `.xcodeproj` that contains Swift Package traits (SE-0450).

## Layout

```
XcodeProj-MinimalProject/
├── Fixtures/
│   └── ProjectWithSwiftPackageTraits.xcodeproj   # contains Remote traits = (); and Local traits = ( NoUIFramework, );
├── Stock/              # Swift package depending on tuist/XcodeProj exact 9.11.0
├── Branch/             # Swift package depending on ../../XcodeProj (local path, branch: support-package-traits)
└── compare.sh          # Runs both and shows the difference
```

## Prerequisites

- The `support-package-traits` branch must be pushed to the remote referenced in `Branch/Package.swift` (currently `https://github.com/chigichan24/XcodeProj.git`). `swift run Branch` fetches from the remote; no local sibling checkout is needed.

## Run

```
./compare.sh
```

Or each side independently:

```
(cd Stock && swift run Stock)
(cd Branch && swift run Branch)
```

## What each side proves

### Stock (tuist/XcodeProj 9.11.0)

Load the fixture and write it back. Greps the output `pbxproj` for `traits = (` lines and reports survival.

Expected: **dropped**. The stock release has no `traits` field on `XCRemoteSwiftPackageReference` / `XCLocalSwiftPackageReference`, so the value is silently discarded on write. `Stock` exits 0 when it confirms the regression (the bug the branch fixes), 1 otherwise.

### Branch (support-package-traits)

Runs four phases against the same fixture:

| Phase | What |
|---|---|
| 1 | Decodes the fixture and prints `traits` on each package reference (shows values survive decode) |
| 2 | Writes the fixture back after setting Remote traits to `nil` / `[]` / `["SQLCipher"]`; greps the resulting `pbxproj` to show how each state serializes (key omitted vs. `( );` vs. `( SQLCipher, );`) |
| 3 | Mutates Local `traits`, writes, reloads, and asserts the values persist |
| 4 | Asserts the type-level invariant that `nil`, `[]`, and `["Foo"]` are all pairwise unequal on `XCRemoteSwiftPackageReference` |

Expected: all checks pass. `Branch` exits 0 on success, 1 otherwise.

## Fixture

`Fixtures/ProjectWithSwiftPackageTraits.xcodeproj` is copied from the fixture added in the XcodeProj branch (`Fixtures/iOS/ProjectWithSwiftPackageTraits.xcodeproj`). Kept here so this repo runs standalone after cloning.
