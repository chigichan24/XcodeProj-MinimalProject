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

- Any `XcodeProj`-based generator that touches a project using SPM traits currently **breaks it on save**. The user cannot opt back in from Xcode without re-selecting every trait.
- Every downstream (Tuist, XcodeGen, etc.) needs this fixed upstream. No reasonable workaround exists at their layer — `traits` isn't in the public XcodeProj model at all.
- The patch is small: two optional `[String]?` fields with `decodeIfPresent` / `if let` encode, plus the pbxproj fixture. No behavior change for projects that don't use traits.

## Reproducing

1. Clone this repo.
2. `./compare.sh`

`Stock/` pulls `tuist/XcodeProj` exactly `9.11.0`. `Branch/` pulls the patch branch. Both exercise the same fixture at `Fixtures/ProjectWithSwiftPackageTraits.xcodeproj`.
