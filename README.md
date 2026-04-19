# Why tuist/XcodeProj should support Swift Package Traits

**TL;DR**: Open a `.xcodeproj` from Xcode 26.4+ that uses SPM traits (SE-0450), round-trip it through stock XcodeProj 9.11.0, and the trait selections vanish. This repo demonstrates the regression and proves a minimal patch fixes it.

## The problem

Xcode 26.4+ writes Swift Package trait selections into `project.pbxproj`:

```
XCLocalSwiftPackageReference "MyLocalPackage" = {
    ...
    relativePath = MyLocalPackage;
    traits = (
        NoUIFramework,
    );
};
```

Stock `tuist/XcodeProj 9.11.0` has no `traits` field on `XCRemoteSwiftPackageReference` / `XCLocalSwiftPackageReference`, so the value is **silently dropped** the first time any tool calls `XcodeProj.write()`. Downstream tools (Tuist, XcodeGen, rules_xcodeproj, etc.) inherit this regression.

## The proof

```
./compare.sh
```

### Stock XcodeProj 9.11.0

```
fixture has 5 trait-related lines:
  traits = (
  NoUIFramework,
  );
  traits = (
  );

after load -> write: 0 trait-related lines:

Result: traits preserved in output pbxproj = NO
```

### The branch ([`chigichan24/XcodeProj@support-package-traits`](https://github.com/chigichan24/XcodeProj/tree/support-package-traits))

Same fixture, same `XcodeProj.write()` call:

```
Phase 1: decode traits from fixture
  Remote  RxSwift traits = []
  Local   MyLocalPackage traits = ["NoUIFramework"]

Phase 3: round-trip — mutate -> write -> reload -> verify
  MyLocalPackage traits = ["SQLCipher", "FTS5", "JSON1"] [OK]

ALL CHECKS PASSED
```

The patch preserves the `nil` / `[]` / populated distinction end-to-end (important because SE-0450 treats `traits: []` as "disable default traits", not the same as absent).

## Why merging matters

- **Silent trait reversion on save**: A generator built on stock XcodeProj that loads a trait-configured project and writes it back discards the user's trait selection. Next time Xcode opens the file, no `traits` key is present, so Xcode falls back to default traits — potentially re-enabling features the user opted out of or linking frameworks they explicitly avoided (e.g. a `NoUIFramework` selection that kept UIKit/AppKit out would quietly come back on).

- **XcodeGen is blocked on this**: [XcodeGen #1585](https://github.com/yonaskolb/XcodeGen/issues/1585) asks for traits in the spec, but it can't be wired up until `traits` exists in the upstream XcodeProj model. The Sentry team currently works around this by hand-committing a `.xcodeproj` with traits ([sentry-cocoa #7578](https://github.com/getsentry/sentry-cocoa/pull/7578)) for their macOS CLI sample.

- **The patch is small**: two optional `[String]?` fields with `decodeIfPresent` / `if let` encode, plus a round-trip fixture and tests. No behavior change for projects that don't use traits. SemVer-minor additive change.

## Reproducing

1. Clone this repo.
2. `./compare.sh`

`Stock/` pulls `tuist/XcodeProj` exactly `9.11.0`. `Branch/` pulls the patch branch. Both exercise the same fixture at `Fixtures/ProjectWithSwiftPackageTraits.xcodeproj`.
